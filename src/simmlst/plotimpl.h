#ifndef PLOTIMPL_H
#define PLOTIMPL_H
//
#include "ui_plot.h"
#include <QtGui>
#include <iostream>
//

using namespace std;

class PlotImpl : public QDialog, public Ui::Plot {
      Q_OBJECT
    public:
      PlotImpl( QWidget * parent = 0, Qt::WFlags f = 0 );
      ~PlotImpl();
      inline void setValues(vector<double>*v) {values=v;}
      void trajectory();
      inline void setMaxX(double maxX) {maxXlab=maxX;}
    private slots:
      void on_exportButton_clicked();
    protected:
      void paintEvent(QPaintEvent*);
      void display_traj(QPaintDevice*qpd);
      vector<double> * values;
      double maxXlab;
  };
#endif
