#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTextDocument>
#include <QPdfWriter>
#include <QStandardPaths>
#include <QDir>
#include <QPageSize>
#include <QRegularExpression>
#include <QPainter>

// Class Helper C++ untuk menulis PDF yang akan dipanggil oleh QML
class AppHelper : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;

    Q_INVOKABLE QString exportToPdf(const QString &title, const QString &body) {
        // Tentukan folder "Documents" di komputer
        QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QDir dir(docPath);
        if (!dir.exists()) dir.mkpath(".");

        // Bersihkan nama file dari karakter aneh untuk judul PDF-nya
        QString cleanTitle = title;
        cleanTitle.replace(QRegularExpression("[^a-zA-Z0-9_ -]"), "");
        if (cleanTitle.isEmpty()) cleanTitle = "Catatan_Newtpad";

        QString filePath = dir.filePath(cleanTitle + ".pdf");

        // Siapkan penulis PDF (Kertas A4, Resolusi 300 DPI)
        QPdfWriter writer(filePath);
        writer.setPageSize(QPageSize(QPageSize::A4));
        writer.setResolution(300);

        QPainter painter(&writer);

        // 1. AMANKAN TEKS: Ubah karakter seperti < dan > agar tidak merusak format HTML
        QString safeTitle = title.toHtmlEscaped();
        QString safeBody = body.toHtmlEscaped();
        safeBody.replace("\n", "<br>"); // Pastikan Enter (baris baru) terbaca di PDF

        // 2. SUSUN HTML: Gunakan format standar yang pasti terbaca
        QString html = QString(
                           "<html><body style='font-family: monospace;'>"
                           "<h1 style='color: #F2542D;'>%1</h1>"
                           "<hr>"
                           "<p style='font-size: 14pt; color: #121212;'>%2</p>"
                           "</body></html>"
                           ).arg(safeTitle, safeBody);

        QTextDocument doc;
        doc.setHtml(html);

        // 3. ATUR LEBAR KERTAS: Ini yang membuat teks mau turun ke bawah (Word Wrap)
        // Jika ini tidak diatur, teks akan lurus terus memanjang ke luar PDF!
        doc.setPageSize(QSizeF(writer.width(), writer.height()));

        // Mulai menggambar ke file PDF
        doc.drawContents(&painter);
        painter.end();

        return filePath;
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Daftarkan class AppHelper ke QML
    qmlRegisterType<AppHelper>("Newtpad.Helpers", 1, 0, "AppHelper");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(QUrl("qrc:/Newtpad/Main.qml"));

    return QGuiApplication::exec();
}

#include "main.moc"