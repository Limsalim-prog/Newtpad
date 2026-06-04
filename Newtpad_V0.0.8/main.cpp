#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTextDocument>
#include <QTextStream>
#include <QStringConverter>
#include <QPdfWriter>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QPageSize>
#include <QRegularExpression>
#include <QPainter>
#include <QQuickTextDocument>
#include <QTextCursor>
#include <QTextCharFormat>
#include <QTcpServer>
#include <QTcpSocket>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDesktopServices>
#include <QUrlQuery>
#include <QSoundEffect>

// Class Helper C++ untuk menulis PDF dan menyimpan/memuat data catatan
class AppHelper : public QObject {
    Q_OBJECT
public:
    explicit AppHelper(QObject *parent = nullptr) : QObject(parent) {
        m_networkManager = new QNetworkAccessManager(this);
    }

    // =============================================
    // FORMAT TEKS (BOLD, ITALIC, UNDERLINE)
    // =============================================
    Q_INVOKABLE void toggleBold(QObject *quickDoc, int selectionStart, int selectionEnd) {
        if (!quickDoc) return;
        QQuickTextDocument *qgDoc = qobject_cast<QQuickTextDocument*>(quickDoc);
        if (!qgDoc) return;
        QTextDocument *doc = qgDoc->textDocument();
        if (!doc) return;

        QTextCursor cursor(doc);
        cursor.setPosition(selectionStart);
        cursor.setPosition(selectionEnd, QTextCursor::KeepAnchor);

        QTextCharFormat format = cursor.charFormat();
        if (format.fontWeight() == QFont::Bold) {
            format.setFontWeight(QFont::Normal);
        } else {
            format.setFontWeight(QFont::Bold);
        }
        cursor.mergeCharFormat(format);
    }

    Q_INVOKABLE void toggleItalic(QObject *quickDoc, int selectionStart, int selectionEnd) {
        if (!quickDoc) return;
        QQuickTextDocument *qgDoc = qobject_cast<QQuickTextDocument*>(quickDoc);
        if (!qgDoc) return;
        QTextDocument *doc = qgDoc->textDocument();
        if (!doc) return;

        QTextCursor cursor(doc);
        cursor.setPosition(selectionStart);
        cursor.setPosition(selectionEnd, QTextCursor::KeepAnchor);

        QTextCharFormat format = cursor.charFormat();
        format.setFontItalic(!format.fontItalic());
        cursor.mergeCharFormat(format);
    }

    Q_INVOKABLE void toggleUnderline(QObject *quickDoc, int selectionStart, int selectionEnd) {
        if (!quickDoc) return;
        QQuickTextDocument *qgDoc = qobject_cast<QQuickTextDocument*>(quickDoc);
        if (!qgDoc) return;
        QTextDocument *doc = qgDoc->textDocument();
        if (!doc) return;

        QTextCursor cursor(doc);
        cursor.setPosition(selectionStart);
        cursor.setPosition(selectionEnd, QTextCursor::KeepAnchor);

        QTextCharFormat format = cursor.charFormat();
        format.setFontUnderline(!format.fontUnderline());
        cursor.mergeCharFormat(format);
    }

    // =============================================
    // PLAY NOTIFICATION SOUND (LOW LATENCY QRC SUPPORT)
    // =============================================
    Q_INVOKABLE void playNotificationSound() {
        static QSoundEffect effect;
        if (effect.source().isEmpty()) {
            effect.setSource(QUrl("qrc:/Notif.mp3"));
            effect.setVolume(1.0);
        }
        effect.play();
    }

    // =============================================
    // SIMPAN CATATAN KE FILE JSON
    // Dipanggil dari QML setiap kali ada perubahan
    // =============================================
    Q_INVOKABLE bool saveNotes(const QString &jsonStr, const QString &userEmail) {
        QString path = notesFilePath(userEmail);
        QDir().mkpath(QFileInfo(path).absolutePath());
        QFile f(path);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            qWarning() << "[Newtpad] Gagal menyimpan catatan ke:" << path;
            return false;
        }
        f.write(jsonStr.toUtf8());
        f.close();
        return true;
    }

    // =============================================
    // MUAT CATATAN DARI FILE JSON
    // Dipanggil dari QML saat pertama kali app buka
    // Mengembalikan "[]" jika belum ada file simpanan
    // =============================================
    Q_INVOKABLE QString loadNotes(const QString &userEmail) {
        QFile f(notesFilePath(userEmail));
        if (!f.exists() || !f.open(QIODevice::ReadOnly)) {
            return "[]"; // Belum ada data tersimpan, kembalikan array kosong
        }
        QString content = QString::fromUtf8(f.readAll());
        f.close();
        return content.isEmpty() ? "[]" : content;
    }

    // =============================================
    // SIMPAN SETTINGS (kategori, dll)
    // =============================================
    Q_INVOKABLE bool saveSettings(const QString &jsonStr) {
        QString path = settingsFilePath();
        QDir().mkpath(QFileInfo(path).absolutePath());
        QFile f(path);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return false;
        f.write(jsonStr.toUtf8());
        f.close();
        return true;
    }

    Q_INVOKABLE QString loadSettings() {
        QFile f(settingsFilePath());
        if (!f.exists() || !f.open(QIODevice::ReadOnly)) return "{}";
        QString content = QString::fromUtf8(f.readAll());
        f.close();
        return content.isEmpty() ? "{}" : content;
    }

    // =============================================
    // CLOUD BACKUP & SYNC SIMULATION (SAVED TO DOCUMENTS)
    // =============================================
    Q_INVOKABLE bool saveBackup(const QString &jsonStr, const QString &userEmail) {
        QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QDir dir(docPath);
        if (!dir.exists()) dir.mkpath(".");
        
        QString filename = "Newtpad_Backup";
        if (!userEmail.isEmpty()) {
            QString sanitized = userEmail;
            sanitized.replace(QRegularExpression("[^a-zA-Z0-9]"), "_");
            filename += "_" + sanitized;
        }
        QString filePath = dir.filePath(filename + ".json");
        QFile f(filePath);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return false;
        f.write(jsonStr.toUtf8());
        f.close();
        return true;
    }

    Q_INVOKABLE QString loadBackup(const QString &userEmail) {
        QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QDir dir(docPath);
        
        QString filename = "Newtpad_Backup";
        if (!userEmail.isEmpty()) {
            QString sanitized = userEmail;
            sanitized.replace(QRegularExpression("[^a-zA-Z0-9]"), "_");
            filename += "_" + sanitized;
        }
        QString filePath = dir.filePath(filename + ".json");
        QFile f(filePath);
        if (!f.exists() || !f.open(QIODevice::ReadOnly)) return "";
        QString content = QString::fromUtf8(f.readAll());
        f.close();
        return content;
    }

    // =============================================
    // FIREBASE REALTIME DATABASE SYNC
    // =============================================
    Q_INVOKABLE void uploadToFirebase(const QString &jsonStr, const QString &userEmail) {
        if (userEmail.isEmpty()) return;

        QString sanitized = userEmail;
        sanitized.replace(QRegularExpression("[^a-zA-Z0-9]"), "_");

        QString urlStr = QString("https://newtpad-default-rtdb.asia-southeast1.firebasedatabase.app/users/%1/notes.json").arg(sanitized);
        QUrl url(urlStr);
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

        emit firebaseSyncStatusChanged("Menyinkronkan ke Cloud... ⏳");

        QNetworkReply *reply = m_networkManager->put(request, jsonStr.toUtf8());
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                emit firebaseSyncStatusChanged("Terakhir disinkronkan: Baru saja ☁️");
            } else {
                qWarning() << "[Newtpad] Gagal sinkronisasi Firebase:" << reply->errorString();
                emit firebaseSyncStatusChanged("Sinkronisasi gagal: Koneksi bermasalah ⚠️");
            }
        });
    }

    Q_INVOKABLE void downloadFromFirebase(const QString &userEmail) {
        if (userEmail.isEmpty()) return;

        QString sanitized = userEmail;
        sanitized.replace(QRegularExpression("[^a-zA-Z0-9]"), "_");

        QString urlStr = QString("https://newtpad-default-rtdb.asia-southeast1.firebasedatabase.app/users/%1/notes.json").arg(sanitized);

        QUrl url(urlStr);
        QNetworkRequest request(url);

        emit firebaseSyncStatusChanged("Mengunduh data dari Cloud... ⏳");

        QNetworkReply *reply = m_networkManager->get(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                QByteArray data = reply->readAll();
                QString jsonStr = QString::fromUtf8(data);
                if (jsonStr.trimmed() == "null" || jsonStr.isEmpty()) {
                    jsonStr = "[]";
                }
                emit firebaseNotesDownloaded(jsonStr);
                emit firebaseSyncStatusChanged("Terakhir disinkronkan: Baru saja ☁️");
            } else {
                qWarning() << "[Newtpad] Gagal mengunduh dari Firebase:" << reply->errorString();
                emit firebaseSyncStatusChanged("Unduh gagal: Koneksi bermasalah ⚠️");
            }
        });
    }

    // =============================================
    // CONVERT DOCUMENT FORMATS (MARKDOWN / RICH TEXT)
    // =============================================
    Q_INVOKABLE void convertToMarkdown(QObject *quickDoc) {
        if (!quickDoc) return;
        QQuickTextDocument *qgDoc = qobject_cast<QQuickTextDocument*>(quickDoc);
        if (!qgDoc) return;
        QTextDocument *doc = qgDoc->textDocument();
        if (!doc) return;

        // Convert structured rich text styles into standard Markdown plaintext
        QString markdown = doc->toMarkdown();
        doc->setPlainText(markdown);
    }

    Q_INVOKABLE void convertToRichText(QObject *quickDoc) {
        if (!quickDoc) return;
        QQuickTextDocument *qgDoc = qobject_cast<QQuickTextDocument*>(quickDoc);
        if (!qgDoc) return;
        QTextDocument *doc = qgDoc->textDocument();
        if (!doc) return;

        // Parse standard Markdown plaintext into structured rich text elements
        QString markdown = doc->toPlainText();
        doc->setMarkdown(markdown);
    }

    Q_INVOKABLE QString getMarkdownFromHtml(const QString &html) {
        QTextDocument doc;
        doc.setHtml(html);
        return doc.toMarkdown();
    }

    Q_INVOKABLE QString getHtmlFromMarkdown(const QString &markdown) {
        QTextDocument doc;
        doc.setMarkdown(markdown);
        return doc.toHtml();
    }

    // =============================================
    // EXPORT KE PDF & FORMAT LAINNYA
    // =============================================
    Q_INVOKABLE QString exportToPdf(const QString &title, const QString &body, bool isMarkdown = false) {
        QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QDir dir(docPath);
        if (!dir.exists()) dir.mkpath(".");

        QString cleanTitle = title;
        cleanTitle.replace(QRegularExpression("[^a-zA-Z0-9_ -]"), "");
        if (cleanTitle.isEmpty()) cleanTitle = "Catatan_Newtpad";

        QString filePath = dir.filePath(cleanTitle + ".pdf");

        QPdfWriter writer(filePath);
        writer.setPageSize(QPageSize(QPageSize::A4));
        writer.setResolution(300);

        QPainter painter(&writer);
        QTextDocument doc;

        if (isMarkdown) {
            QString markdownContent = "# " + title + "\n\n---\n\n" + body;
            doc.setMarkdown(markdownContent);
        } else {
            QString safeTitle = title.toHtmlEscaped();
            QString safeBody;
            if (body.contains("<html") || body.contains("<p") || body.contains("<b>") || body.contains("<i>") || body.contains("<u>")) {
                safeBody = body;
            } else {
                safeBody = body.toHtmlEscaped();
                safeBody.replace("\n", "<br>");
            }

            QString html = QString(
                               "<html><body style='font-family: Arial, sans-serif; margin: 40px;'>"
                               "<h1 style='color: #F2542D;'>%1</h1>"
                               "<hr style='border: 1px solid #E5E5E5;'>"
                               "<div style='font-size: 12pt; color: #121212; line-height: 1.6;'>%2</div>"
                               "</body></html>"
                               ).arg(safeTitle, safeBody);
            doc.setHtml(html);
        }

        doc.setPageSize(QSizeF(writer.width(), writer.height()));
        doc.drawContents(&painter);
        painter.end();

        // Buka file PDF yang berhasil diexport secara otomatis
        QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));

        return filePath;
    }

    Q_INVOKABLE bool exportNoteAs(const QUrl &fileUrl, const QString &title, const QString &body, bool isMarkdown) {
        QString filePath = fileUrl.toLocalFile();
        if (filePath.isEmpty()) return false;
        
        QFileInfo info(filePath);
        QDir().mkpath(info.absolutePath());

        if (filePath.endsWith(".pdf", Qt::CaseInsensitive)) {
            QPdfWriter writer(filePath);
            writer.setPageSize(QPageSize(QPageSize::A4));
            writer.setResolution(300);

            QPainter painter(&writer);
            QTextDocument doc;

            if (isMarkdown) {
                QString markdownContent = "# " + title + "\n\n---\n\n" + body;
                doc.setMarkdown(markdownContent);
            } else {
                QString safeTitle = title.toHtmlEscaped();
                QString safeBody;
                if (body.contains("<html") || body.contains("<p") || body.contains("<b>") || body.contains("<i>") || body.contains("<u>")) {
                    safeBody = body;
                } else {
                    safeBody = body.toHtmlEscaped();
                    safeBody.replace("\n", "<br>");
                }

                QString html = QString(
                                   "<html><body style='font-family: Arial, sans-serif; margin: 40px;'>"
                                   "<h1 style='color: #F2542D;'>%1</h1>"
                                   "<hr style='border: 1px solid #E5E5E5;'>"
                                   "<div style='font-size: 12pt; color: #121212; line-height: 1.6;'>%2</div>"
                                   "</body></html>"
                                   ).arg(safeTitle, safeBody);
                doc.setHtml(html);
            }

            doc.setPageSize(QSizeF(writer.width(), writer.height()));
            doc.drawContents(&painter);
            painter.end();
            return true;
        }

        // Export as Markdown
        if (filePath.endsWith(".md", Qt::CaseInsensitive)) {
            QFile file(filePath);
            if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
            QTextStream out(&file);
            out.setEncoding(QStringConverter::Utf8);
            if (isMarkdown) {
                out << "# " << title << "\n\n" << body;
            } else {
                QTextDocument doc;
                doc.setHtml(body);
                out << "# " << title << "\n\n" << doc.toMarkdown();
            }
            file.close();
            return true;
        }

        // Export as HTML
        if (filePath.endsWith(".html", Qt::CaseInsensitive)) {
            QFile file(filePath);
            if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
            QTextStream out(&file);
            out.setEncoding(QStringConverter::Utf8);
            if (isMarkdown) {
                QTextDocument doc;
                doc.setMarkdown(body);
                out << "<html><head><meta charset='utf-8'><title>" << title.toHtmlEscaped() << "</title></head>";
                out << "<body style='font-family: Arial, sans-serif; margin: 40px;'>";
                out << "<h1 style='color: #F2542D;'>" << title.toHtmlEscaped() << "</h1><hr>";
                out << doc.toHtml();
                out << "</body></html>";
            } else {
                out << "<html><head><meta charset='utf-8'><title>" << title.toHtmlEscaped() << "</title></head>";
                out << "<body style='font-family: Arial, sans-serif; margin: 40px;'>";
                out << "<h1 style='color: #F2542D;'>" << title.toHtmlEscaped() << "</h1><hr>";
                out << body;
                out << "</body></html>";
            }
            file.close();
            return true;
        }

        // Export as Plain Text
        if (filePath.endsWith(".txt", Qt::CaseInsensitive)) {
            QFile file(filePath);
            if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
            QTextStream out(&file);
            out.setEncoding(QStringConverter::Utf8);
            out << title << "\n";
            for (int i = 0; i < title.length(); ++i) out << "=";
            out << "\n\n";
            if (isMarkdown) {
                out << body;
            } else {
                QTextDocument doc;
                doc.setHtml(body);
                out << doc.toPlainText();
            }
            file.close();
            return true;
        }

        return false;
    }

    Q_INVOKABLE void openFile(const QUrl &fileUrl) {
        QDesktopServices::openUrl(fileUrl);
    }

    Q_INVOKABLE QString sanitizeFileName(const QString &name) const {
        QString clean = name;
        clean.replace(QRegularExpression("[^a-zA-Z0-9_ -]"), "");
        if (clean.isEmpty()) clean = "Catatan_Newtpad";
        return clean;
    }

    Q_INVOKABLE QUrl defaultExportUrl(const QString &title) {
        QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QString cleanTitle = sanitizeFileName(title);
        return QUrl::fromLocalFile(docPath + "/" + cleanTitle + ".pdf");
    }

private:
    // Path file penyimpanan — di folder AppData sistem (aman & persisten)
    QString notesFilePath(const QString &userEmail) const {
        QString filename = "newtpad_notes";
        if (!userEmail.isEmpty()) {
            QString sanitized = userEmail;
            sanitized.replace(QRegularExpression("[^a-zA-Z0-9]"), "_");
            filename += "_" + sanitized;
        }
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        + "/" + filename + ".json";
    }
    QString settingsFilePath() const {
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        + "/newtpad_settings.json";
    }

signals:
    void firebaseNotesDownloaded(const QString &jsonStr);
    void firebaseSyncStatusChanged(const QString &status);

private:
    QNetworkAccessManager *m_networkManager = nullptr;
};

class GoogleLoginHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStatusChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY profileChanged)
    Q_PROPERTY(QString userEmail READ userEmail NOTIFY profileChanged)
    Q_PROPERTY(QString userAvatar READ userAvatar NOTIFY profileChanged)
    Q_PROPERTY(QString clientId READ clientId WRITE setClientId NOTIFY clientIdChanged)
    Q_PROPERTY(QString clientSecret READ clientSecret WRITE setClientSecret NOTIFY clientSecretChanged)

public:
    explicit GoogleLoginHelper(QObject *parent = nullptr) : QObject(parent) {
        m_server = new QTcpServer(this);
        m_networkManager = new QNetworkAccessManager(this);
        connect(m_server, &QTcpServer::newConnection, this, &GoogleLoginHelper::onNewConnection);
    }

    Q_INVOKABLE void startLogin() {
        if (m_server->isListening()) {
            m_server->close();
        }
        
        if (!m_server->listen(QHostAddress::LocalHost, 8080)) {
            emit loginFailed("Gagal membuka port lokal 8080 untuk redirect.");
            return;
        }

        QString authUrl = QString("https://accounts.google.com/o/oauth2/v2/auth?"
                                  "client_id=%1&"
                                  "redirect_uri=http://127.0.0.1:8080&"
                                  "response_type=code&"
                                  "scope=openid%20profile%20email")
                          .arg(m_clientId);

        QDesktopServices::openUrl(QUrl(authUrl));
    }

    Q_INVOKABLE void logout() {
        m_isLoggedIn = false;
        m_userName = "";
        m_userEmail = "";
        m_userAvatar = "";
        emit profileChanged();
        emit loginStatusChanged();
    }
    
    Q_INVOKABLE void forceLoginMock(const QString &name, const QString &email) {
        m_userName = name;
        m_userEmail = email;
        m_userAvatar = "";
        m_isLoggedIn = true;
        emit profileChanged();
        emit loginStatusChanged();
        emit loginSuccess();
    }

    bool isLoggedIn() const { return m_isLoggedIn; }
    QString userName() const { return m_userName; }
    QString userEmail() const { return m_userEmail; }
    QString userAvatar() const { return m_userAvatar; }
    QString clientId() const { return m_clientId; }
    QString clientSecret() const { return m_clientSecret; }

    void setClientId(const QString &clientId) {
        if (m_clientId != clientId) {
            m_clientId = clientId;
            emit clientIdChanged();
        }
    }

    void setClientSecret(const QString &clientSecret) {
        if (m_clientSecret != clientSecret) {
            m_clientSecret = clientSecret;
            emit clientSecretChanged();
        }
    }

signals:
    void loginStatusChanged();
    void profileChanged();
    void clientIdChanged();
    void clientSecretChanged();
    void loginFailed(const QString &error);
    void loginSuccess();

private slots:
    void onNewConnection() {
        QTcpSocket *socket = m_server->nextPendingConnection();
        if (!socket) return;

        connect(socket, &QTcpSocket::readyRead, this, [this, socket]() {
            QByteArray request = socket->readAll();
            QString requestStr = QString::fromUtf8(request);

            QString firstLine = requestStr.split("\r\n").first();
            QStringList tokens = firstLine.split(' ');
            QString code;
            if (tokens.size() >= 2) {
                QUrl url("http://127.0.0.1:8080" + tokens[1]);
                QUrlQuery query(url.query());
                if (query.hasQueryItem("code")) {
                    code = query.queryItemValue("code");
                }
            }

            if (!code.isEmpty()) {
                QString response = "HTTP/1.1 200 OK\r\n"
                                   "Content-Type: text/html; charset=utf-8\r\n\r\n"
                                   "<html><head><title>Login Sukses</title>"
                                   "<style>body { font-family: sans-serif; text-align: center; margin-top: 50px; background-color: #121212; color: white; }</style>"
                                   "</head><body>"
                                   "<h2>Login Newtpad Berhasil! 🎉</h2>"
                                   "<p>Silakan tutup tab ini dan kembali ke aplikasi.</p>"
                                   "</body></html>";
                socket->write(response.toUtf8());
                socket->flush();
                socket->disconnectFromHost();

                m_server->close();
                exchangeCodeForToken(code);
            } else {
                QString response = "HTTP/1.1 400 Bad Request\r\n\r\n";
                socket->write(response.toUtf8());
                socket->flush();
                socket->disconnectFromHost();
            }
        });
    }

private:
    void exchangeCodeForToken(const QString &code) {
        QUrl url("https://oauth2.googleapis.com/token");
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

        QUrlQuery params;
        params.addQueryItem("code", code);
        params.addQueryItem("client_id", m_clientId);
        params.addQueryItem("client_secret", m_clientSecret);
        params.addQueryItem("redirect_uri", "http://127.0.0.1:8080");
        params.addQueryItem("grant_type", "authorization_code");

        QNetworkReply *reply = m_networkManager->post(request, params.toString(QUrl::FullyEncoded).toUtf8());
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                emit loginFailed("Gagal menukar token: " + reply->errorString());
                return;
            }

            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            QJsonObject obj = doc.object();

            QString accessToken = obj["access_token"].toString();
            if (!accessToken.isEmpty()) {
                fetchUserProfile(accessToken);
            } else {
                emit loginFailed("Access token kosong.");
            }
        });
    }

    void fetchUserProfile(const QString &accessToken) {
        QUrl url("https://www.googleapis.com/oauth2/v3/userinfo");
        QNetworkRequest request(url);
        request.setRawHeader("Authorization", "Bearer " + accessToken.toUtf8());

        QNetworkReply *reply = m_networkManager->get(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                emit loginFailed("Gagal mengambil profil: " + reply->errorString());
                return;
            }

            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            QJsonObject obj = doc.object();

            m_userName = obj["name"].toString();
            m_userEmail = obj["email"].toString();
            m_userAvatar = obj["picture"].toString();
            m_isLoggedIn = true;

            emit profileChanged();
            emit loginStatusChanged();
            emit loginSuccess();
        });
    }

    QTcpServer *m_server = nullptr;
    QNetworkAccessManager *m_networkManager = nullptr;
    bool m_isLoggedIn = false;
    QString m_userName;
    QString m_userEmail;
    QString m_userAvatar;
    QString m_clientId = "73985825796-o0ord60svgk2j8opibhvfpeimasg65tr.apps.googleusercontent.com";
    QString m_clientSecret = "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";
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Set nama organisasi & aplikasi agar AppDataLocation menghasilkan path yang benar
    app.setOrganizationName("Newtpad");
    app.setApplicationName("Newtpad");

    // Daftarkan class helper ke QML
    qmlRegisterType<AppHelper>("Newtpad.Helpers", 1, 0, "AppHelper");
    qmlRegisterType<GoogleLoginHelper>("Newtpad.Helpers", 1, 0, "GoogleLoginHelper");

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