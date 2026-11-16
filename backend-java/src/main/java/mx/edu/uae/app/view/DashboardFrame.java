package mx.edu.uae.app.view;

import java.awt.BorderLayout;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import mx.edu.uae.app.model.Usuario;

public class DashboardFrame extends JFrame {
    public DashboardFrame(Usuario usuario) {
        super("App Unificada UAE");
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.add(new JLabel("Bienvenido/a, " + usuario.getNombreCompleto() + " (" + usuario.getRol() + ")",
                SwingConstants.CENTER), BorderLayout.NORTH);
        panel.add(new JLabel("Los módulos estarán disponibles en próximas etapas.", SwingConstants.CENTER),
                BorderLayout.CENTER);
        add(panel);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(600, 300);
        setLocationRelativeTo(null);
    }
}
