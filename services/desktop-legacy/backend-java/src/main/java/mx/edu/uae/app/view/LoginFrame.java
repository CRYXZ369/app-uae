package mx.edu.uae.app.view;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.util.Arrays;
import java.util.Optional;
import java.util.concurrent.ExecutionException;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;
import javax.swing.SwingUtilities;
import javax.swing.SwingWorker;
import mx.edu.uae.app.dao.JdbcUsuarioDAO;
import mx.edu.uae.app.dao.UsuarioDAO;
import mx.edu.uae.app.model.Usuario;

public class LoginFrame extends JFrame {
    private final JTextField email = new JTextField(25);
    private final JPasswordField password = new JPasswordField(25);
    private final JButton login = new JButton("Ingresar");
    private final UsuarioDAO usuarios = new JdbcUsuarioDAO();

    public LoginFrame() {
        super("App Unificada UAE - Inicio de sesión");
        JPanel fields = new JPanel(new GridLayout(2, 2, 8, 8));
        fields.add(new JLabel("Correo institucional:"));
        fields.add(email);
        fields.add(new JLabel("Contraseña:"));
        fields.add(password);
        add(fields, BorderLayout.CENTER);
        add(login, BorderLayout.SOUTH);
        login.addActionListener(event -> iniciarSesion());
        getRootPane().setDefaultButton(login);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        pack();
        setLocationRelativeTo(null);
    }

    private void iniciarSesion() {
        String correo = email.getText().trim();
        char[] clave = password.getPassword();
        password.setText("");
        login.setEnabled(false);
        new SwingWorker<Optional<Usuario>, Void>() {
            @Override
            protected Optional<Usuario> doInBackground() throws Exception {
                try {
                    return usuarios.login(correo, clave);
                } finally {
                    Arrays.fill(clave, '\0');
                }
            }

            @Override
            protected void done() {
                login.setEnabled(true);
                try {
                    Optional<Usuario> usuario = get();
                    if (usuario.isPresent()) {
                        new DashboardFrame(usuario.get()).setVisible(true);
                        dispose();
                    } else {
                        JOptionPane.showMessageDialog(LoginFrame.this, "Correo o contraseña incorrectos.");
                    }
                } catch (InterruptedException ex) {
                    Thread.currentThread().interrupt();
                    JOptionPane.showMessageDialog(LoginFrame.this, "Se interrumpió el inicio de sesión.");
                } catch (ExecutionException ex) {
                    JOptionPane.showMessageDialog(LoginFrame.this, "No fue posible iniciar sesión. Revise la conexión.");
                }
            }
        }.execute();
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new LoginFrame().setVisible(true));
    }
}
