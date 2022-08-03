import QtQuick 1.0

Item {
    function calcPhotoPos(index, playerNum) {
        /*
        int pad = _m_roomLayout->m_scenePadding + _m_roomLayout->m_photoRoomPadding;
        int tablew = log_box_widget->x() - pad * 2;
        int tableh = sceneRect().height() - pad * 2 - dashboard->boundingRect().height();
        if ((ServerInfo.GameMode == "04_1v3" || ServerInfo.GameMode == "06_3v3") && game_started)
            tableh -= _m_roomLayout->m_photoVDistance;
        int photow = _m_photoLayout->m_normalWidth;
        int photoh = _m_photoLayout->m_normalHeight;
        double hGap = _m_roomLayout->m_photoHDistance;
        double vGap = _m_roomLayout->m_photoVDistance;
        double col1 = photow + hGap;
        double col2 = tablew - col1;
        double row1 = photoh + vGap;
        double row2 = tableh;
        */
        /*
        Layout:
           col1           col2
        _______________________
        |_2_|______1_______|_0_| row1
        |   |              |   |
        | 4 |    table     | 3 |
        |___|______________|___|
        |      dashboard       |
        ------------------------
        region 5 = 0 + 3, region 6 = 2 + 4, region 7 = 0 + 1 + 2
        */

        var regularSeatIndex = [
            [1],
            [5, 6],
            [5, 1, 6],
            [3, 1, 1, 4],
            [3, 7, 7, 7, 4],
            [5, 5, 1, 1, 6, 6],
            [5, 5, 1, 1, 1, 6, 6],
            [5, 5, 1, 1, 1, 1, 6, 6],
            [3, 3, 7, 7, 7, 7, 7, 4, 4]
        ];

        var seatRegions = [
            QRectF(col2, pad, col1, row1),
            QRectF(col1, pad, col2 - col1, row1),
            QRectF(pad, pad, col1, row1),
            QRectF(col2, row1, col1, row2 - row1),
            QRectF(pad, row1, col1, row2 - row1),
            QRectF(col2, pad, col1, row2),
            QRectF(pad, pad, col1, row2),
            QRectF(pad, pad, col1 + col2, row1)
        ];
        /*
        The horizontal flags are:
        Constant            Value   Description
        Qt::AlignLeft       0x0001  Aligns with the left edge.
        Qt::AlignRight      0x0002  Aligns with the right edge.
        Qt::AlignHCenter    0x0004  Centers horizontally in the available space.
        Qt::AlignJustify    0x0008  Justifies the text in the available space.

        The vertical flags are:
        Constant            Value   Description
        Qt::AlignTop        0x0020  Aligns with the top.
        Qt::AlignBottom     0x0040  Aligns with the bottom.
        Qt::AlignVCenter    0x0080  Centers vertically in the available space.
        Qt::AlignBaseline   0x0100  Aligns with the baseline.

        You can use only one of the horizontal flags at a time. There is one two-dimensional flag:
        Constant        Value                   Description
        Qt::AlignCenter AlignVCenter | AlignH   CenterCenters in both dimensions
        */

        var aligns = [
            0x2 | 0x20,
            0x4 | 0x20,
            0x1 | 0x20,
            0x2 | 0x80,
            0x1 | 0x80,
            0x2 | 0x80,
            0x1 | 0x80,
            0x4 | 0x20,
        ];

        var orients = [
            // 0x1 is horizontal, 0x2 is vertical
            1, 1, 1, 2, 2, 2, 2, 1,
        ];
        var region = regularSeatIndex[playerNum - 2][index - 1];
        var align = aligns[region];
        var orient = orients[region];
        /*
        void RoomScene::_dispersePhotos(QList<Photo *> &photos, QRectF fillRegion,
            Qt::Orientation orientation, Qt::Alignment align)
        {
            double photoWidth = _m_photoLayout->m_normalWidth;
            double photoHeight = _m_photoLayout->m_normalHeight;
            int numPhotos = photos.size();
            if (numPhotos == 0) return;
            Qt::Alignment hAlign = align & Qt::AlignHorizontal_Mask;
            Qt::Alignment vAlign = align & Qt::AlignVertical_Mask;

            double startX = 0, startY = 0, stepX, stepY;

            if (orientation == Qt::Horizontal) {
                double maxWidth = fillRegion.width();
                stepX = qMax(photoWidth + G_ROOM_LAYOUT.m_photoHDistance, maxWidth / numPhotos);
                stepY = 0;
            } else {
                stepX = 0;
                stepY = G_ROOM_LAYOUT.m_photoVDistance + photoHeight;
            }

            switch (vAlign) {
            case Qt::AlignTop: startY = fillRegion.top() + photoHeight / 2; break;
            case Qt::AlignBottom: startY = fillRegion.bottom() - photoHeight / 2 - stepY * (numPhotos - 1); break;
            case Qt::AlignVCenter: startY = fillRegion.center().y() - stepY * (numPhotos - 1) / 2.0; break;
            default: Q_ASSERT(false);
            }
            switch (hAlign) {
            case Qt::AlignLeft: startX = fillRegion.left() + photoWidth / 2; break;
            case Qt::AlignRight: startX = fillRegion.right() - photoWidth / 2 - stepX * (numPhotos - 1); break;
            case Qt::AlignHCenter: startX = fillRegion.center().x() - stepX * (numPhotos - 1) / 2.0; break;
            default: Q_ASSERT(false);
            }

            for (int i = 0; i < numPhotos; i++) {
                Photo *photo = photos[i];
                QPointF newPos = QPointF(startX + stepX * i, startY + stepY * i);
                photo->setPos(newPos);
            }
        }
        */    
    }
}