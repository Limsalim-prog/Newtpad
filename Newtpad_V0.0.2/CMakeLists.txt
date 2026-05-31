cmake_minimum_required(VERSION 3.16)

project(Newtpad VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

# 1. KASIH TAU POSISI BARU MAIN.CPP
qt_add_executable(appNewtpad
    main.cpp
)

# 2. KASIH TAU POSISI BARU QML FILES-NYA
qt_add_qml_module(appNewtpad
    URI Newtpad
    QML_FILES
        Main.qml
        NoteCard.qml
        EditNotePage.qml
)

set_target_properties(appNewtpad PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appNewtpad
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appNewtpad
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


