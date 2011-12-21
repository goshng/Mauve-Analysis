#ifndef GUIIMPL_H
#define GUIIMPL_H
//
#include <QtGui>
#include "ui_gui.h"
#include "arg.h"
#include "plotimpl.h"

class GuiImpl : public QMainWindow, public Ui::Gui {
      Q_OBJECT
    public:
      GuiImpl( QWidget * parent = 0, Qt::WFlags f = 0 );
    private slots:
      void on_ltSelect_clicked();
      void on_dataSelect_clicked();
      void on_cgSelect_clicked();
      void on_dotSelect_clicked();
      void on_run_clicked();
      void on_help_clicked();
      void on_popSizeShow_clicked();
  };
#endif


