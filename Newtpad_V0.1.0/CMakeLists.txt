cmake_minimum_required(VERSION 3.16)

project(Newtpad VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia Network)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appNewtpad
    main.cpp
)

qt_add_qml_module(appNewtpad
    URI Newtpad
    RESOURCE_PREFIX "/"
    QML_FILES
        Main.qml
        NoteCard.qml
        EditNotePage.qml
        CustomDialog.qml
        TodoListEditor.qml
        PhotoAttachment.qml
        VoiceAttachment.qml
        PasswordDialog.qml
        ShareDialog.qml
        AddCategoryDialog.qml
        ReminderDialog.qml
        SplashScreenPage.qml
        NotificationBanner.qml
        OpenNoteDialog.qml
    RESOURCES
        Notif.mp3
        logo.jpeg
        QML_FILES AddCategoryDialog.qml
        QML_FILES ReminderDialog.qml
        QML_FILES SplashScreenPage.qml
        QML_FILES NotificationBanner.qml
        QML_FILES OpenNoteDialog.qml

)

set_target_properties(appNewtpad PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appNewtpad
    PRIVATE Qt6::Quick Qt6::Multimedia Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appNewtpad
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)