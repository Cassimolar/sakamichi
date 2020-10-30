#ifndef MAXCARDSVIEWDIALOG_H
#define MAXCARDSVIEWDIALOG_H

class ClientPlayer;

class MaxCardsViewDialogUI;

class MaxCardsViewDialog : public QDialog
{
    Q_OBJECT

public:
    MaxCardsViewDialog(QWidget *parent = 0);
    ~MaxCardsViewDialog();

private:
    MaxCardsViewDialogUI *ui;

private slots:
    void showMaxCards();
};

#endif
