
#include <Trade\PositionInfo.mqh>
#include  "ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"

input int    InpDoubleInDayTopupOrders = 3;             // The total topup orders
//input string InpDoubleInDayLotsRatioChain = "3;1;3;4";    // The volume ratios (topup orders) vs initial order, by ";"
input double InpDoubleInDayLotsRatioChain1 = 2.2;    // Volumn 1
input double InpDoubleInDayLotsRatioChain2 = 4.2;    // Volumn 2
input double InpDoubleInDayLotsRatioChain3 = 8;    // Volumn 3
input double InpDoubleInDayLotsRatioChain4 = 1;    // Volumn 4
input double InpDoubleInDayLotsRatioChain5 = 1;    // Volumn 5
input double InpDoubleInDayLotsRatioChain6 = 1;    // Volumn 6

//input string InpDoubleInDayDistanceRatioChain = "1;2;3;4"; // The distance ratios (topup orders) vs initial order, by ";"
input double InpDoubleInDayDistanceRatioChain1 = 2;    // Distance 1
input double InpDoubleInDayDistanceRatioChain2 = 2.8;    // Distance 2
input double InpDoubleInDayDistanceRatioChain3 = 3.66;    // Distance 3
input double InpDoubleInDayDistanceRatioChain4 = 5;    // Distance 4
input double InpDoubleInDayDistanceRatioChain5 = 6;    // Distance 5
input double InpDoubleInDayDistanceRatioChain6 = 7;    // Distance 6

input double InpDoubleInDayTpRatioVsSLFromLastTopup = 1.8;  // The ratio of TP vs SL from last order
// ============================================
// Class thể hiện phương pháp "Double In A Day""
// ============================================
class CDoubleInDay
{
    private:
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        ulong m_magicNumber;
        string m_appendComment;
        
        int m_slPoints;
        int m_topupOrders;
        double m_lots[];
        double m_distancesRatio[];
        
        bool m_existencePos[], m_existencePending[], m_takeProfitFromTop2;
        ulong m_tickets[];
        double m_tpRatioFromLastTopup;
        string m_interPreComment;
        bool m_disabled;
    public:
        void TakeProfitFromTop2(bool val)
        {
            m_takeProfitFromTop2 = val;
        }
        
        void TpRatioFromLastTopup(double ratio)
        {
            m_tpRatioFromLastTopup = ratio;
        }
        void LotRatioChain(string lotRatioChain)
        {
            string arr[];
            Split(lotRatioChain, ";", arr);
            CastArrayToDouble(arr, m_lots);
        }
        
        // Thiết lập ghi chú khi tạo lệnh
        void SetAppendComment(string appendComment)
        {
            m_appendComment = appendComment;
        }
        // Thiết lập số dây lớn nhất
        void Topup(int topups)
        {
            m_topupOrders = topups;
            ArrayResize(m_existencePos, topups + 1);
            ArrayResize(m_existencePending, topups + 1);
            ArrayResize(m_tickets, topups + 1);
        }
        void DistancesRatio(string distanceRatio)
        {
            string arr[];
            Split(distanceRatio, ";", arr);
            CastArrayToDouble(arr, m_distancesRatio);
        }
        void InternalComment(string comment)
        {
            m_interPreComment = comment;
        }
        bool ExistTopup()
        {
            for(int idx = 1; idx <= m_topupOrders; idx++)
                if(m_existencePos[idx])
                    return true;
             return false;
        }
        void Disable(bool disable)
        {
            m_disabled = disable;
            if(disable)
                CloseAllPendingOrders();
        }
        // Khởi tạo các thông số cho đối tượng CHedge
        bool Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       ulong magicNumber)
        {
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            m_magicNumber = magicNumber;
            
            m_tpRatioFromLastTopup = 2;
            m_disabled = false;
            m_takeProfitFromTop2 = false;
            
            // Validation
            if(InpDoubleInDayDistanceRatioChain1 <= 0)
            {
                Print("Error: Volumn 1 <= 0");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain2 <= 0)
            {
                Print("Error: Volumn 2 <= 0");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain3 <= 0)
            {
                Print("Error: Volumn 3 <= 0");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain4 <= 0)
            {
                Print("Error: Volumn 4 <= 0");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain5 <= 0)
            {
                Print("Error: Volumn 5 <= 0");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain6 <= 0)
            {
                Print("Error: Volumn 6 <= 0");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain2 <= InpDoubleInDayDistanceRatioChain1)
            {
                Print("Error: Distance 2 <= Distance 1");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain3 <= InpDoubleInDayDistanceRatioChain2)
            {
                Print("Error: Distance 3 <= Distance 2");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain4 <= InpDoubleInDayDistanceRatioChain3)
            {
                Print("Error: Distance 4 <= Distance 3");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain5 <= InpDoubleInDayDistanceRatioChain4)
            {
                Print("Error: Distance 5 <= Distance 4");
                return false;
            }
            if(InpDoubleInDayDistanceRatioChain6 <= InpDoubleInDayDistanceRatioChain5)
            {
                Print("Error: Distance 6 <= Distance 5");
                return false;
            }
            if(InpDoubleInDayTpRatioVsSLFromLastTopup <= 0)
            {
                Print("Error: [The ratio of TP vs SL from last order] <= 0");
                return false;
            }
    
            return true;
        }
        void Setting(string comment)
        {
            string ratioChain = "";
            if(InpDoubleInDayLotsRatioChain1 > 0)
                ratioChain += InpDoubleInDayLotsRatioChain1 + ";";
            if(InpDoubleInDayLotsRatioChain2 > 0)
                ratioChain += InpDoubleInDayLotsRatioChain2 + ";";
            if(InpDoubleInDayLotsRatioChain3 > 0)
                ratioChain += InpDoubleInDayLotsRatioChain3 + ";";
            if(InpDoubleInDayLotsRatioChain4 > 0)
                ratioChain += InpDoubleInDayLotsRatioChain4 + ";";
            if(InpDoubleInDayLotsRatioChain5 > 0)
                ratioChain += InpDoubleInDayLotsRatioChain5 + ";";
            if(InpDoubleInDayLotsRatioChain6 > 0)
                ratioChain += InpDoubleInDayLotsRatioChain6 + ";";
            LotRatioChain(ratioChain);
            SetAppendComment(comment);
            Topup(InpDoubleInDayTopupOrders);
            string distanceChain = "";
            if(InpDoubleInDayDistanceRatioChain1 > 0)
                distanceChain += InpDoubleInDayDistanceRatioChain1 + ";";
            if(InpDoubleInDayDistanceRatioChain2 > 0)
                distanceChain += InpDoubleInDayDistanceRatioChain2 + ";";
            if(InpDoubleInDayDistanceRatioChain3 > 0)
                distanceChain += InpDoubleInDayDistanceRatioChain3 + ";";
            if(InpDoubleInDayDistanceRatioChain4 > 0)
                distanceChain += InpDoubleInDayDistanceRatioChain4 + ";";
            if(InpDoubleInDayDistanceRatioChain5 > 0)
                distanceChain += InpDoubleInDayDistanceRatioChain5 + ";";
            if(InpDoubleInDayDistanceRatioChain6 > 0)
                distanceChain += InpDoubleInDayDistanceRatioChain6 + ";";
            DistancesRatio(distanceChain);
            TpRatioFromLastTopup(InpDoubleInDayTpRatioVsSLFromLastTopup);
            InternalComment("x2");
        }
        // ===================================
        // Xử lý chính
        // ===================================
        void Process(int limit)
        {
            if(m_disabled)
                return;
            
            //if(count == 0)
            //    return;
            LoadExistence();
            
            //LoadPending();
                
            ProcessTopupOrders();
            
            double profit = GetTotalProfit();
            double totalLotOfActivePos = GetTotalLot();
            int spread = m_infoCurrency.symbol_info().Spread()/2;
            double deltaSpreadMoney = PointsToMoney(m_symbolCurrency, spread, totalLotOfActivePos);
            
            if(profit <= deltaSpreadMoney && m_existencePos[1] 
               && (!m_takeProfitFromTop2 
                   || 
                   (m_takeProfitFromTop2 && !IsTopup2Exist())
                  )
              )
            {
                CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, m_appendComment + ";01;");
                CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, CombineComment());
                CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, m_appendComment + ";01;");
                CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, CombineComment());
            }
            if(profit > 0 && m_existencePos[1] && IsTopup2Exist() && m_takeProfitFromTop2)
            {
                CPositionInfo pos;
                if(pos.SelectByTicket(m_tickets[0]))
                {
                    string items[];
                    Split(pos.Comment(), ";", items);
                    int slPoints = (int)StringToInteger(items[2]);
                    if(slPoints > 0)
                    {
                        double mustProfit = (double)DoubleToString(PointsToMoney(m_symbolCurrency, slPoints, pos.Volume()), 
                                                           m_infoCurrency.symbol_info().Digits());
                        if(profit <= mustProfit)
                        {
                            CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, m_appendComment + ";01;");
                            CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, CombineComment());
                            CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, m_appendComment + ";01;");
                            CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, CombineComment());
                        }
                    }
                }
            }
        }
    protected:
        bool IsTopup2Exist()
        {
            if(ArraySize(m_existencePos) > 2 && m_existencePos[2])
                return true;
            return false;
        }
        void LoadExistence()
        {
            ulong tickets[];
            SearchActiveOpenPosition(m_symbolCurrency, m_magicNumber, 
                                     m_appendComment, true, true, tickets);

            ClearExistence();
            ClearTickets();
            for(int idx = 0; idx < ArraySize(tickets); idx++)
            {
                CPositionInfo pos;
                if(pos.SelectByTicket(tickets[idx]))
                {
                    string comment = pos.Comment();
                    // Kiểm tra lệnh đầu tiên (init)
                    string initComment = m_appendComment + ";01;";
                    if(StringFind(comment, initComment) >= 0)
                    {
                        m_existencePos[0] = true;
                        m_tickets[0] = tickets[idx];
                    }
                        
                    for(int idxTopup = 1; idxTopup <= m_topupOrders; idxTopup++)
                    {
                        string findComment = CombineComment() + ";" + PaddingLeft(idxTopup + 1, 2, "0") + ";";
                        if(StringFind(comment, findComment) >= 0)
                        {
                            m_existencePos[idxTopup] = true;
                            m_tickets[idxTopup] = tickets[idx];
                        }
                    }
                }
            }
        }
        string CombineComment()
        {
            return m_appendComment + "_" + m_interPreComment;
        }
        bool ExistPendingOrder(bool isSell, int topupNum)
        {
            string comment = CombineComment() + ";" + PaddingLeft(topupNum + 1, 2, "0") + ";";
            if(isSell)
                return GetPendingOrdersByType(m_symbolCurrency, m_magicNumber,
                                              ORDER_TYPE_SELL_STOP, comment) > 0;
            else
                return GetPendingOrdersByType(m_symbolCurrency, m_magicNumber,
                                              ORDER_TYPE_BUY_STOP, comment) > 0;
        }
        void ProcessTopupOrders()
        {
            if(m_existencePos[0])
            {
                CPositionInfo pos;
                if(pos.SelectByTicket(m_tickets[0]))
                {
                    string items[];
                    Split(pos.Comment(), ";", items);
                    double slDistance = PointsToPriceShift(m_symbolCurrency, (int)items[2]);
                    //double slDistance = MathAbs(pos.PriceOpen() - pos.StopLoss());
                    bool isSellPos = pos.PositionType() == POSITION_TYPE_SELL;
                    double tp = pos.TakeProfit();
                    double calculateTPDistance = slDistance * (m_distancesRatio[m_topupOrders - 1] + m_tpRatioFromLastTopup);
                    double targetTP;
                    if(isSellPos)
                        targetTP = pos.PriceOpen() - calculateTPDistance;
                    else
                        targetTP = pos.PriceOpen() + calculateTPDistance;
                    if(DoubleToString(tp, m_infoCurrency.symbol_info().Digits()) 
                       != DoubleToString(targetTP, m_infoCurrency.symbol_info().Digits()))
                        UpdateSLTP(m_tickets[0], pos.StopLoss(), targetTP);
                    // Create topup orders
                    for(int idxTopup = 1; idxTopup <= m_topupOrders; idxTopup++)
                    {
                        if(!m_existencePos[idxTopup] && !ExistPendingOrder(isSellPos, idxTopup))
                        {
                            if(isSellPos)
                            {
                                double entry = pos.PriceOpen() - slDistance * m_distancesRatio[idxTopup - 1];
                                //double tp = targetTP;
                                double lot = (double)DoubleToString(pos.Volume() * m_lots[idxTopup - 1], 2);
                                string topupComment = CombineComment() + ";" 
                                                      + PaddingLeft(idxTopup + 1, 2, "0") + ";";
                                m_trader.SellStop(lot, entry, m_symbolCurrency, 0, targetTP, 0, 0, topupComment);
                            }
                            else
                            {
                                double entry = pos.PriceOpen() + slDistance * m_distancesRatio[idxTopup - 1];
                                //double tp = targetTP;
                                double lot = (double)DoubleToString(pos.Volume() * m_lots[idxTopup - 1], 2);
                                string topupComment = CombineComment() + ";" 
                                                      + PaddingLeft(idxTopup + 1, 2, "0") + ";";
                                m_trader.BuyStop(lot, entry, m_symbolCurrency, 0, targetTP, 0, 0, topupComment);
                            
                            }
                        }
                    }
                }
            }
            else
            {
                CloseAllPendingOrders();
            }
        }
        // =====================================
        // Cập nhật SL và TP cho ticket
        // =====================================
        bool UpdateSLTP(ulong ticket, double sl, double tp)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            return m_trader.PositionModify(ticket, sl, tp);
        }
        void ClearExistence()
        {
            for(int idx = 0; idx < ArraySize(m_existencePos); idx++)
            {
                m_existencePos[idx] = false;
            }
        }
        void ClearTickets()
        {
            for(int idx = 0; idx < ArraySize(m_tickets); idx++)
            {
                m_tickets[idx] = 0;
            }
        }
        // ===================================
        // Lấy thông tin lot tiếp theo
        // ===================================
        double NextLot(int topupNum)
        {
            if(topupNum > 0 && topupNum <= ArraySize(m_lots))
                return m_lots[topupNum - 1];
            return 0;
        }
        
        // ===================================
        // Đóng toàn bộ lệnh chờ SELL và BUY
        // ===================================
        void CloseAllPendingOrders()
        {
            for(int idx = 1; idx <= m_topupOrders; idx++)
            {
                string comment = CombineComment() + ";" + PaddingLeft(idx + 1, 2, "0") + ";";
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, comment);
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, comment);
            }
        }
        
        // ===================================
        // Tinh tổng lợi nhuận bao gồm bù trừ phí swap
        // ===================================
        double GetTotalProfit()
        {
            double sumProfit = 0;
        
            for(int i=PositionsTotal()-1; i>=0; i--) {
                string CounterSymbol=PositionGetSymbol(i);
                ulong ticket = PositionGetTicket(i);
        
                if(PositionSelectByTicket(ticket)) {
                    if(m_symbolCurrency == CounterSymbol
                            && PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                        string comment = PositionGetString(POSITION_COMMENT);
                        
                        // Init position
                        string initPosComment = m_appendComment + ";01;";
                        if(StringFind(comment, initPosComment) >= 0)
                        {
                            sumProfit += PositionGetDouble(POSITION_PROFIT);
                            sumProfit += PositionGetDouble(POSITION_SWAP);
                            sumProfit += PositionGetDouble(POSITION_COMMISSION);
                        }
                        // Topup
                        string topupComment = CombineComment() + ";";
                        if(StringFind(comment, topupComment) >= 0) 
                        {
                            sumProfit += PositionGetDouble(POSITION_PROFIT);
                            sumProfit += PositionGetDouble(POSITION_SWAP);
                            sumProfit += PositionGetDouble(POSITION_COMMISSION);
                        }
                    }
                }
            }
            return sumProfit;
        }
        
        double GetTotalLot() {
            ulong tickets[];
            SearchActiveOpenPosition(m_symbolCurrency, m_magicNumber, 
                                    m_appendComment, true, true, tickets);
            double totalVol = 0;
            for(int idx = 0; idx < ArraySize(tickets); idx++)
            {
                CPositionInfo pos;
                if(pos.SelectByTicket(tickets[idx]))
                {
                    totalVol += pos.Volume();
                }
            }
            return totalVol;
        }
        
        
};