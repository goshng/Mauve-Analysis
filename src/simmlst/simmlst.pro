TEMPLATE = app
CONFIG += release
LIBS = -lgslcblas -lgsl
QMAKE_CXXFLAGS = -g
SOURCES = simmlst.cpp \
 arg.cpp \
 data.cpp \
 guiimpl.cpp \
 popsize.cpp \
 plotimpl.cpp
HEADERS += arg.h \
 rng.h \
 data.h \
 guiimpl.h \
 popsize.h \
 plotimpl.h
FORMS += gui.ui plot.ui
QT += core gui
