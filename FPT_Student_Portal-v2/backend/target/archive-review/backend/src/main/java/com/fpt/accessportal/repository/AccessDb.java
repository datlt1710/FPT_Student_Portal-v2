package com.fpt.accessportal.repository;

import jakarta.annotation.PostConstruct;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Repository
public class AccessDb {
  private static final Logger log = LoggerFactory.getLogger(AccessDb.class);

  @Value("${access.db.path}")
  private String path;

  @PostConstruct
  public void verify() {
    path = Path.of(path).toAbsolutePath().normalize().toString();
    if (!Files.isRegularFile(Path.of(path)))
      throw new IllegalStateException(
          "Khong tim thay Access DB: "
              + Path.of(path).toAbsolutePath()
              + ". Dat ACCESS_DB_PATH tro den file .accdb da tao.");
    log.info("Access database: {}", path);
  }

  public Connection open() throws SQLException {
    return DriverManager.getConnection(
        "jdbc:ucanaccess://"
            + Path.of(path).toAbsolutePath().normalize()
            + ";memory=false;immediatelyReleaseResources=true");
  }

  public List<Map<String, Object>> query(String sql, Object... args) throws SQLException {
    try (Connection c = open();
        PreparedStatement p = c.prepareStatement(sql)) {
      for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
      try (ResultSet rs = p.executeQuery()) {
        List<Map<String, Object>> out = new ArrayList<>();
        ResultSetMetaData md = rs.getMetaData();
        while (rs.next()) {
          // UCanAccess may uppercase joined column labels (e.g. ENROLLMENTID).
          Map<String, Object> row = new java.util.TreeMap<>(String.CASE_INSENSITIVE_ORDER);
          for (int i = 1; i <= md.getColumnCount(); i++) {
            Object o = rs.getObject(i);
            if (o instanceof java.sql.Timestamp t) o = t.toLocalDateTime().toString();
            else if (o instanceof java.sql.Date d) o = d.toLocalDate().toString();
            else if (o instanceof java.sql.Time t) o = t.toLocalTime().toString();
            row.put(md.getColumnLabel(i), o);
          }
          out.add(row);
        }
        return out;
      }
    }
  }

  public int update(String sql, Object... args) throws SQLException {
    try (Connection c = open();
        PreparedStatement p = c.prepareStatement(sql)) {
      for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
      return p.executeUpdate();
    }
  }
}
