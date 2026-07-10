package com.starchitex.backend.config;

import com.starchitex.backend.security.CustomUserDetails;
import org.springframework.jdbc.datasource.DelegatingDataSource;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import javax.sql.DataSource;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

public class RlsDataSource extends DelegatingDataSource {

    public RlsDataSource(DataSource targetDataSource) {
        super(targetDataSource);
    }

    @Override
    public Connection getConnection() throws SQLException {
        Connection connection = super.getConnection();
        applyRlsContext(connection);
        return wrapConnection(connection);
    }

    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        Connection connection = super.getConnection(username, password);
        applyRlsContext(connection);
        return wrapConnection(connection);
    }

    private void applyRlsContext(Connection connection) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        
        Integer branchId = null;
        Integer guestId = null;
        boolean isSuperAdmin = false;

        if (auth != null && auth.getPrincipal() instanceof CustomUserDetails userDetails) {
            branchId = userDetails.getBranchId();
            guestId = userDetails.getGuestId();
            isSuperAdmin = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_System Administrator") || 
                                   a.getAuthority().equals("ROLE_Hotel Owner") || 
                                   a.getAuthority().equals("ROLE_Sales Executive"));
        }

        try (Statement stmt = connection.createStatement()) {
            stmt.execute("SET app.current_branch_id = '" + (branchId != null ? branchId : "") + "'");
            stmt.execute("SET app.current_guest_id = '" + (guestId != null ? guestId : "") + "'");
            stmt.execute("SET app.is_super_admin = '" + isSuperAdmin + "'");
        } catch (SQLException e) {
            throw new RuntimeException("Failed to set PostgreSQL RLS variables", e);
        }
    }

    private Connection wrapConnection(Connection connection) {
        return (Connection) Proxy.newProxyInstance(
                Connection.class.getClassLoader(),
                new Class<?>[]{Connection.class},
                new RlsConnectionInvocationHandler(connection)
        );
    }

    private static class RlsConnectionInvocationHandler implements InvocationHandler {
        private final Connection target;

        public RlsConnectionInvocationHandler(Connection target) {
            this.target = target;
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            if ("close".equals(method.getName())) {
                try (Statement stmt = target.createStatement()) {
                    stmt.execute("RESET app.current_branch_id; RESET app.current_guest_id; RESET app.is_super_admin;");
                } catch (SQLException e) {
                    // Ignore on close
                }
            }
            return method.invoke(target, args);
        }
    }
}
