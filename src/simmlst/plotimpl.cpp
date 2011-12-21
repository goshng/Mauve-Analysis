#include "plotimpl.h"
//
PlotImpl::PlotImpl( QWidget * parent, Qt::WFlags f)
    : QDialog(parent, f) {
  setupUi(this);
  values=NULL;
  maxXlab=0;
}

PlotImpl::~PlotImpl() {
  delete(values);
}

void PlotImpl::paintEvent(QPaintEvent*) {
  display_traj(this);
}

void PlotImpl::display_traj(QPaintDevice*qpd) {
  if (values==NULL) return;
  double minY=values->at(0);
  double maxY=values->at(0);
  minY=0.0;
  for (unsigned int i=1;i<values->size();i++) {
      if (values->at(i)>maxY) maxY=values->at(i);
      if (values->at(i)<minY) minY=values->at(i);
    }
  double minX=0.0;
  double maxX=values->size()-1;
  QPainter painter(qpd);
  painter.drawText(QRectF(width()*0.0,height()*0.1,100,100),QString::number(maxY));
  painter.drawText(QRectF(width()*0.0,height()*0.9,100,100),QString::number(minY));
  painter.drawText(QRectF(width()*0.1,height()*0.95,100,100),QString::number(0));
  painter.drawText(QRectF(width()*0.9,height()*0.95,100,100),QString::number(maxXlab));
  
  QPointF * points=(QPointF*)calloc(values->size(),sizeof(QPointF));
  for (unsigned int i=0;i<values->size();i++) {
      double x,y;
      x=i;
      y=values->at(i);
      x=(x-minX)/(maxX-minX);
      y=(y-minY)/(maxY-minY);
      points[i]=QPointF(x,1.0-y);
    }

  painter.translate(width()/10.0,height()/10.0);
  painter.scale(width()*0.8,height()*0.8);
  painter.drawPolyline(points,values->size());
  painter.drawRect(QRectF(-0.05,-0.05,1.1,1.1));
  free(points);
}

void PlotImpl::on_exportButton_clicked() {
  QString qstr = QFileDialog::getSaveFileName(this, tr("Save picture file"),".",tr("Joint Photographic Experts Group (*.jpg *.jpeg);;Windows Bitmap (*.bmp);;Portable Network Graphics (*.png);;Portable Pixmap (*.ppm);;X11 Bitmap (*.xbm *.xpm);;PostScript Format (*.ps);;Abode PDF Format (*.pdf)"));
  if (qstr==NULL) return;
    if (qstr.endsWith("ps") || qstr.endsWith("pdf")) {
  	QPrinter qprint;
	qprint.setOutputFileName(qstr);
	qprint.setOrientation( QPrinter::Landscape);
	  display_traj(&qprint);
      return;
    }
  QImage image(width(),height(),QImage::Format_RGB32);
  image.invertPixels();//Fill image in white
  display_traj(&image);
  image.save(qstr);
}


