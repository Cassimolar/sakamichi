#include "maxcardsviewdialog.h"

#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "roomscene.h"

class MaxCardsViewDialogUI
{
public:
    MaxCardsViewDialogUI()
    {
        player = new QComboBox;
        final = new QLineEdit;
        final->setReadOnly(true);

    }

    QComboBox *player;
    QLineEdit *final;
};

MaxCardsViewDialog::MaxCardsViewDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle(tr("MaxCards view"));

    QFormLayout *layout = new QFormLayout;

    ui = new MaxCardsViewDialogUI;

    RoomScene::FillPlayerNames(ui->player, false);

    connect(ui->player, SIGNAL(currentIndexChanged(int)), this, SLOT(showMaxCards()));

    layout->addRow(tr("Player"), ui->player);

    layout->addRow(tr("MaxCards"), ui->final);
    setLayout(layout);

    showMaxCards();
}

MaxCardsViewDialog::~MaxCardsViewDialog()
{
    delete ui;
}

void MaxCardsViewDialog::showMaxCards()
{
    QString player_name = ui->player->itemData(ui->player->currentIndex()).toString();

    const ClientPlayer *player = ClientInstance->getPlayer(player_name);

    ui->final->setText(QString::number(player->getMaxCards()));
}
