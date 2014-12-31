#-------------------------------------------------
#
# Project created by QtCreator 2014-10-14T17:02:38
#
#-------------------------------------------------

QT       += testlib

QT       -= gui

TARGET = enumtest
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app

DEFINES += SRCDIR=\\\"$$PWD/\\\"

HEADERS += \
    ../EnumUtils.hpp \
    ../Enums.hpp

SOURCES += \
    ../Enums.cpp \
    enumtest.cpp

OTHER_FILES += \
    ../UserInfo.txt
