import javax.swing.*;
import java.awt.*;
import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.zip.*;

public class BTWInstallerGUI {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(BTWInstallerGUI::createGUI);
    }

    private static void createGUI() {
        JFrame frame = new JFrame("Better Than Wolves Installer");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(500, 350);
        frame.setLayout(new BorderLayout());

        JPanel panel = new JPanel(new GridLayout(0,1,5,5));

        // Выбор версии
        panel.add(new JLabel("Выберите версию Minecraft:"));
        String[] versions = {"1.2.5","1.4.5","1.4.7","1.5","1.5.1","1.5.2","1.6.1","1.6.2"};
        JComboBox<String> versionBox = new JComboBox<>(versions);
        panel.add(versionBox);

        // Выбор мода
        panel.add(new JLabel("Выберите файл мода (.zip):"));
        JTextField modField = new JTextField();
        JButton browseBtn = new JButton("Обзор");
        JPanel modPanel = new JPanel(new BorderLayout());
        modPanel.add(modField, BorderLayout.CENTER);
        modPanel.add(browseBtn, BorderLayout.EAST);
        panel.add(modPanel);

        browseBtn.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                modField.setText(chooser.getSelectedFile().getAbsolutePath());
            }
        });

        // Папка установки
        panel.add(new JLabel("Папка установки:"));
        JTextField pathField = new JTextField(".minecraft_installer");
        panel.add(pathField);

        // Кнопка установки
        JButton installBtn = new JButton("Установить");
        panel.add(installBtn);

        JTextArea logArea = new JTextArea();
        logArea.setEditable(false);
        JScrollPane scrollPane = new JScrollPane(logArea);

        frame.add(panel, BorderLayout.NORTH);
        frame.add(scrollPane, BorderLayout.CENTER);

        installBtn.addActionListener(e -> {
            installBtn.setEnabled(false);
            new Thread(() -> {
                try {
                    String version = (String) versionBox.getSelectedItem();
                    Path modFile = Paths.get(modField.getText());
                    Path installDir = Paths.get(pathField.getText());
                    Files.createDirectories(installDir);

                    Path tmpDir = installDir.resolve(".tmp");
                    Files.createDirectories(tmpDir);

                    logArea.append("Скачиваем Minecraft " + version + "...\n");
                    Path mcJar = tmpDir.resolve("minecraft_" + version + ".jar");
                    downloadMinecraft(version, mcJar, logArea);

                    logArea.append("Применяем мод: " + modFile.getFileName() + "\n");
                    Path workDir = tmpDir.resolve("mc");
                    Files.createDirectories(workDir);
                    unzip(mcJar, workDir);
                    unzip(modFile, workDir);

                    deleteDirectory(workDir.resolve("META-INF"));

                    Path finalJar = installDir.resolve("ModLoader-" + version + ".jar");
                    zipDirectory(workDir, finalJar);

                    logArea.append("Готово! " + finalJar.toAbsolutePath() + "\n");
                } catch (Exception ex) {
                    logArea.append("Ошибка: " + ex.getMessage() + "\n");
                    ex.printStackTrace();
                } finally {
                    installBtn.setEnabled(true);
                }
            }).start();
        });

        frame.setVisible(true);
    }

    // ===== Вспомогательные функции =====
    static void downloadMinecraft(String version, Path dest, JTextArea log) throws Exception {
        String manifest = new String(new URL("https://launchermeta.mojang.com/mc/game/version_manifest.json").openStream().readAllBytes());
        int idx = manifest.indexOf("\"id\": \"" + version + "\"");
        String urlLine = manifest.substring(idx, manifest.indexOf("}", idx));
        String url = urlLine.replaceAll(".*\"url\": \"([^\"]+)\".*", "$1");
        String versionJson = new String(new URL(url).openStream().readAllBytes());
        String jarUrl = versionJson.replaceAll(".*\"url\": \"([^\"]+\\.jar)\".*", "$1");
        downloadFile(jarUrl, dest, log);
    }

    static void downloadFile(String urlStr, Path dest, JTextArea log) throws Exception {
        try (InputStream in = new URL(urlStr).openStream()) {
            Files.copy(in, dest, StandardCopyOption.REPLACE_EXISTING);
            log.append("Скачано: " + dest.getFileName() + "\n");
        }
    }

    static void unzip(Path zipFile, Path dest) throws Exception {
        Files.createDirectories(dest);
        try (ZipInputStream zis = new ZipInputStream(Files.newInputStream(zipFile))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                Path outPath = dest.resolve(entry.getName());
                if (entry.isDirectory()) Files.createDirectories(outPath);
                else {
                    Files.createDirectories(outPath.getParent());
                    Files.copy(zis, outPath, StandardCopyOption.REPLACE_EXISTING);
                }
            }
        }
    }

    static void deleteDirectory(Path dir) throws IOException {
        if (!Files.exists(dir)) return;
        Files.walk(dir).sorted((a,b)->b.compareTo(a)).map(Path::toFile).forEach(File::delete);
    }

    static void zipDirectory(Path sourceDir, Path zipFile) throws IOException {
        try (ZipOutputStream zs = new ZipOutputStream(Files.newOutputStream(zipFile))) {
            Files.walk(sourceDir).filter(Files::isRegularFile).forEach(path -> {
                ZipEntry zipEntry = new ZipEntry(sourceDir.relativize(path).toString());
                try {
                    zs.putNextEntry(zipEntry);
                    Files.copy(path, zs);
                    zs.closeEntry();
                } catch (IOException e) { throw new RuntimeException(e); }
            });
        }
    }
            }
