Attribute VB_Name = "SeedSpringSummer2026"
Option Compare Database
Option Explicit

' Import this module into the intended Access database.
' Run AddSpringSummer2026. Existing rows are never updated or deleted.
' Adds demo data for ALL existing students. Does not modify Students.

Private Function DemoEnsureRow(ByVal db As DAO.Database, _
    ByVal tableName As String, ByVal idField As String, _
    ByVal criteria As String, ByVal columns As Variant, _
    ByVal values As Variant, ByRef added As Long) As Long

    Dim rs As DAO.Recordset
    Dim idx As Long
    Set rs = db.OpenRecordset("SELECT * FROM [" & tableName & _
        "] WHERE " & criteria, dbOpenDynaset)
    If rs.EOF Then
        rs.AddNew
        For idx = LBound(columns) To UBound(columns)
            rs.Fields(CStr(columns(idx))).Value = values(idx)
        Next idx
        rs.Update
        rs.Bookmark = rs.LastModified
        added = added + 1
    End If
    DemoEnsureRow = CLng(rs.Fields(idField).Value)
    rs.Close
End Function

Private Function DemoDateSQL(ByVal value As Date) As String
    DemoDateSQL = "#" & Format$(value, "mm\/dd\/yyyy hh\:nn\:ss") & "#"
End Function

Public Sub AddSpringSummer2026()
    On Error GoTo Failed

    Dim db As DAO.Database
    Dim ws As DAO.Workspace
    Dim students As DAO.Recordset
    Dim courseRow As DAO.Recordset
    Dim terms As Variant, codes As Variant, termCodes As Variant
    Dim starts As Variant, examStarts As Variant
    Dim assessments As Variant, weights As Variant
    Dim term As Long, course As Long, week As Long, assessment As Long
    Dim sid As Long, cid As Long, eid As Long, sessionID As Long
    Dim unusedID As Long, added As Long, studentCount As Long
    Dim lessonDate As Date, startTime As Date, endTime As Date
    Dim score As Double, attendance As String, criteria As String
    Dim inTransaction As Boolean, message As String

    Set db = CurrentDb
    Set ws = DBEngine.Workspaces(0)

    If MsgBox("Database: " & db.Name & vbCrLf & vbCrLf & _
        "Add Spring/Summer 2026 DEMO data for ALL existing students?" & vbCrLf & _
        "Existing data will not be updated or deleted." & vbCrLf & _
        "Make a database backup before continuing.", _
        vbYesNo + vbQuestion + vbDefaultButton2, "Spring / Summer demo") <> vbYes Then Exit Sub

    terms = Array("Spring 2026", "Summer 2026")
    codes = Array(Array("DBI202", "SWE201c", "KOR321", "MLN111"), _
                  Array("PRJ301", "SWD392", "EXE101", "PRM392"))
    starts = Array(DateSerial(2026, 1, 12), DateSerial(2026, 5, 11))
    examStarts = Array(DateSerial(2026, 4, 10), DateSerial(2026, 8, 10))
    assessments = Array("Quiz 1", "Assignment 1", "Progress Test", "Final exam")
    weights = Array(0.1, 0.2, 0.3, 0.4)

    Set students = db.OpenRecordset("SELECT StudentID FROM Students ORDER BY StudentID", dbOpenSnapshot)
    If students.EOF Then Err.Raise vbObjectError + 2100, , "Students is empty."

    ws.BeginTrans
    inTransaction = True

    Do Until students.EOF
        sid = CLng(students!StudentID)
        studentCount = studentCount + 1
        For term = 0 To 1
            termCodes = codes(term)
            For course = 0 To 3
                Set courseRow = db.OpenRecordset( _
                    "SELECT CourseID FROM Courses WHERE CourseCode='" & _
                    Replace(CStr(termCodes(course)), "'", "''") & "'", dbOpenSnapshot)
                If courseRow.EOF Then Err.Raise vbObjectError + 2101, , _
                    "Missing course: " & CStr(termCodes(course))
                cid = CLng(courseRow!CourseID)
                courseRow.Close
                Set courseRow = Nothing

                criteria = "StudentID=" & sid & " AND CourseID=" & cid & _
                    " AND Semester='" & terms(term) & "'"
                eid = DemoEnsureRow(db, "Enrollments", "EnrollmentID", criteria, _
                    Array("StudentID", "CourseID", "Semester", "ClassCode"), _
                    Array(sid, cid, terms(term), "DEMO-" & _
                        IIf(term = 0, "SP26-", "SU26-") & termCodes(course)), added)

                For week = 0 To 11
                    lessonDate = CDate(starts(term)) + week * 7 + course
                    If course Mod 2 = 0 Then
                        startTime = TimeSerial(7, 30, 0)
                        endTime = TimeSerial(9, 50, 0)
                    Else
                        startTime = TimeSerial(10, 0, 0)
                        endTime = TimeSerial(12, 20, 0)
                    End If
                    criteria = "EnrollmentID=" & eid & _
                        " AND SessionDate=" & DemoDateSQL(lessonDate) & _
                        " AND StartTime=" & DemoDateSQL(startTime)
                    sessionID = DemoEnsureRow(db, "TimetableSessions", "SessionID", criteria, _
                        Array("EnrollmentID", "SessionDate", "StartTime", "EndTime", _
                              "Room", "StudyMode", "SessionStatus"), _
                        Array(eid, lessonDate, startTime, endTime, _
                              "DEMO-" & CStr(101 + course), "Offline", "Completed"), added)

                    attendance = IIf(week Mod 5 = 4, "Absent", "Present")
                    criteria = "SessionID=" & sessionID & " AND StudentID=" & sid
                    unusedID = DemoEnsureRow(db, "AttendanceRecords", "AttendanceID", criteria, _
                        Array("SessionID", "StudentID", "AttendanceStatus"), _
                        Array(sessionID, sid, attendance), added)
                Next week

                For assessment = 0 To 3
                    ' First course in each term: 4.0 = NOT PASSED.
                    ' Other courses: 7.3 / 7.6 / 7.9 = PASSED.
                    If course = 0 Then score = 4# Else score = 7# + course * 0.3
                    criteria = "EnrollmentID=" & eid & " AND AssessmentName='" & _
                        assessments(assessment) & "'"
                    unusedID = DemoEnsureRow(db, "Marks", "MarkID", criteria, _
                        Array("EnrollmentID", "AssessmentName", "Score", "Weight"), _
                        Array(eid, assessments(assessment), score, weights(assessment)), added)
                Next assessment

                criteria = "EnrollmentID=" & eid & " AND ExamType='DEMO-Final'"
                unusedID = DemoEnsureRow(db, "ExamSchedules", "ExamID", criteria, _
                    Array("EnrollmentID", "ExamDate", "ExamTime", "Room", "ExamType"), _
                    Array(eid, CDate(examStarts(term)) + course, TimeSerial(9, 0, 0), _
                          "DEMO-EX" & CStr(201 + course), "DEMO-Final"), added)
            Next course
        Next term
        students.MoveNext
    Loop

    ws.CommitTrans
    inTransaction = False
    students.Close
    MsgBox "Completed! Students: " & studentCount & vbCrLf & _
        "New records: " & added & vbCrLf & _
        "Spring: select week 12/01/2026 in Flutter." & vbCrLf & _
        "Summer: select week 11/05/2026 in Flutter.", vbInformation
    Exit Sub

Failed:
    message = "Error " & Err.Number & ": " & Err.Description
    On Error Resume Next
    If inTransaction Then ws.Rollback
    If Not students Is Nothing Then students.Close
    If Not courseRow Is Nothing Then courseRow.Close
    MsgBox message & vbCrLf & "Transaction rollback attempted.", vbCritical
End Sub
