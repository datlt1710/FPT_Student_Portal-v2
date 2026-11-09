Attribute VB_Name = "CreateSemesters"
Option Compare Database
Option Explicit

Private Function HasTable(ByVal db As DAO.Database, ByVal tableName As String) As Boolean
    Dim item As DAO.TableDef
    For Each item In db.TableDefs
        If StrComp(item.Name, tableName, vbTextCompare) = 0 Then
            HasTable = True
            Exit Function
        End If
    Next item
End Function

Private Function HasField(ByVal table As DAO.TableDef, ByVal fieldName As String) As Boolean
    Dim item As DAO.Field
    For Each item In table.Fields
        If StrComp(item.Name, fieldName, vbTextCompare) = 0 Then
            HasField = True
            Exit Function
        End If
    Next item
End Function

Private Function HasIndex(ByVal table As DAO.TableDef, ByVal indexName As String) As Boolean
    Dim item As DAO.Index
    For Each item In table.Indexes
        If StrComp(item.Name, indexName, vbTextCompare) = 0 Then
            HasIndex = True
            Exit Function
        End If
    Next item
End Function

Private Sub AddTermIfMissing(ByVal db As DAO.Database, ByVal code As String, _
    ByVal name As String, ByVal startDate As Date, ByVal endDate As Date)
    Dim rs As DAO.Recordset
    Set rs = db.OpenRecordset("SELECT * FROM Semesters WHERE SemesterCode='" & _
        Replace(code, "'", "''") & "'", dbOpenDynaset)
    If rs.EOF Then
        rs.AddNew
        rs!SemesterCode = code
        rs!SemesterName = name
        rs!StartDate = startDate
        rs!EndDate = endDate
        rs.Update
    End If
    rs.Close
End Sub

Public Sub CreateSemesterTable()
    On Error GoTo Failed
    Dim db As DAO.Database
    Dim ws As DAO.Workspace
    Dim relation As DAO.Relation
    Dim linkField As DAO.Field
    Dim item As DAO.Relation
    Dim check As DAO.Recordset
    Dim fieldName As Variant
    Dim inTransaction As Boolean, relationExists As Boolean
    Dim message As String, updated As Long

    Set db = CurrentDb
    Set ws = DBEngine.Workspaces(0)
    If Not HasTable(db, "Enrollments") Then Err.Raise vbObjectError + 2200, , "Missing Enrollments table."
    If Not HasField(db.TableDefs("Enrollments"), "Semester") Then _
        Err.Raise vbObjectError + 2201, , "Missing Enrollments.Semester."

    If MsgBox("Database: " & db.Name & vbCrLf & vbCrLf & _
        "Create Semesters and link existing enrollments?" & vbCrLf & _
        "Keep the old Semester column. Back up this database first." & vbCrLf & _
        "Close open table tabs before continuing.", _
        vbYesNo + vbQuestion + vbDefaultButton2, "Create semester table") <> vbYes Then Exit Sub

    ws.BeginTrans
    inTransaction = True

    If Not HasTable(db, "Semesters") Then
        db.Execute "CREATE TABLE Semesters (" & _
            "SemesterID COUNTER CONSTRAINT PK_Semesters PRIMARY KEY," & _
            "SemesterCode TEXT(30) NOT NULL," & _
            "SemesterName TEXT(50) NOT NULL," & _
            "StartDate DATETIME,EndDate DATETIME)", dbFailOnError
        db.TableDefs.Refresh
    End If

    For Each fieldName In Array("SemesterID", "SemesterCode", "SemesterName", "StartDate", "EndDate")
        If Not HasField(db.TableDefs("Semesters"), CStr(fieldName)) Then _
            Err.Raise vbObjectError + 2202, , "Existing Semesters table is missing: " & CStr(fieldName)
    Next fieldName
    If Not HasIndex(db.TableDefs("Semesters"), "UX_Semesters_Code") Then
        db.Execute "CREATE UNIQUE INDEX UX_Semesters_Code ON Semesters (SemesterCode)", dbFailOnError
        db.TableDefs.Refresh
    End If
    If Not HasIndex(db.TableDefs("Semesters"), "UX_Semesters_Name") Then
        db.Execute "CREATE UNIQUE INDEX UX_Semesters_Name ON Semesters (SemesterName)", dbFailOnError
        db.TableDefs.Refresh
    End If

    ' Demo boundaries. Change these dates before running if your calendar differs.
    AddTermIfMissing db, "SPRING2026", "Spring 2026", DateSerial(2026, 1, 1), DateSerial(2026, 4, 30)
    AddTermIfMissing db, "SUMMER2026", "Summer 2026", DateSerial(2026, 5, 1), DateSerial(2026, 8, 31)
    AddTermIfMissing db, "FALL2026", "Fall 2026", DateSerial(2026, 9, 1), DateSerial(2027, 1, 3)

    ' Stop before mapping if a semester label has no corresponding row.
    Set check = db.OpenRecordset( _
        "SELECT E.EnrollmentID,E.Semester FROM Enrollments AS E " & _
        "LEFT JOIN Semesters AS S ON E.Semester=S.SemesterName " & _
        "WHERE S.SemesterID IS NULL", dbOpenSnapshot)
    If Not check.EOF Then
        message = "Unknown semester on EnrollmentID=" & check!EnrollmentID & _
            ": " & Nz(check!Semester, "(empty)")
        check.Close
        Set check = Nothing
        Err.Raise vbObjectError + 2203, , message
    End If
    check.Close
    Set check = Nothing

    If Not HasField(db.TableDefs("Enrollments"), "SemesterID") Then
        db.Execute "ALTER TABLE Enrollments ADD COLUMN SemesterID LONG", dbFailOnError
        db.TableDefs.Refresh
    End If
    If db.TableDefs("Enrollments").Fields("SemesterID").Type <> dbLong Then _
        Err.Raise vbObjectError + 2204, , "Enrollments.SemesterID must be Number / Long Integer."

    ' Refuse to overwrite an existing, conflicting mapping.
    Set check = db.OpenRecordset( _
        "SELECT E.EnrollmentID FROM Enrollments AS E INNER JOIN Semesters AS S " & _
        "ON E.Semester=S.SemesterName WHERE E.SemesterID IS NOT NULL " & _
        "AND E.SemesterID<>S.SemesterID", dbOpenSnapshot)
    If Not check.EOF Then
        message = "Conflicting SemesterID on EnrollmentID=" & check!EnrollmentID
        check.Close
        Set check = Nothing
        Err.Raise vbObjectError + 2205, , message
    End If
    check.Close
    Set check = Nothing

    db.Execute "UPDATE Enrollments AS E INNER JOIN Semesters AS S " & _
        "ON E.Semester=S.SemesterName SET E.SemesterID=S.SemesterID " & _
        "WHERE E.SemesterID IS NULL", dbFailOnError
    updated = db.RecordsAffected

    For Each item In db.Relations
        If item.Name = "FK_Enrollments_Semesters" Then relationExists = True
    Next item
    If Not relationExists Then
        Set relation = db.CreateRelation("FK_Enrollments_Semesters", "Semesters", "Enrollments", 0)
        Set linkField = relation.CreateField("SemesterID")
        linkField.ForeignName = "SemesterID"
        relation.Fields.Append linkField
        db.Relations.Append relation
    End If

    ws.CommitTrans
    inTransaction = False
    MsgBox "DONE! Semesters created/checked." & vbCrLf & _
        "Enrollments mapped: " & updated & vbCrLf & _
        "Old Semester column was kept for the current backend." & vbCrLf & _
        "Close and reopen table tabs to see new columns.", vbInformation
    Exit Sub

Failed:
    message = "Error " & Err.Number & ": " & Err.Description
    On Error Resume Next
    If Not check Is Nothing Then check.Close
    If inTransaction Then ws.Rollback
    MsgBox message & vbCrLf & "Rollback attempted. Check schema before retrying.", vbCritical
End Sub
