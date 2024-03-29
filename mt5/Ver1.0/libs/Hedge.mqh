
#include <Trade\PositionInfo.mqh>
#include  "ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"

input group "Thiết lập Hedge"
input bool   InpUseHedge = true;            // Sử dụng phương pháp hedge
input int    InpHedgeMaxWire = 7;           // Số dây lớn nhất
input double InpHedgeRiskReward = 2;        // Tỉ lệ RR
input string InpHedgeLotsChain = "0.01;0.02;0.02;0.03;0.05;0.07;0.1;0.15;0.23;0.35;0.52;0.78;1.17;1.75;2.63;3.95;5.92;8.88;13.32;19.98;29.97;44.95;67.43;101.15;151.72"; // Mảng khối lượng cho các dây
input double InpHedgeExpectProfit = 1;      // Lợi nhuận mong đợi khi phát sinh dây hedge

// ===================================
// Class thể hiện phương pháp hedge
// ===================================
class CHedge
{
    private:
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        double m_riskReward;
        int m_maxWireTotal;
        string m_appendComment;
        ulong m_magicNumber;
        
        // Flag cho biết đã đạt tới ngưỡng lớn nhất của dây tạo mới
        bool m_reachMaxWire;
        string m_lotChain;
        double m_expectProfit;
        bool m_disabled;
        string m_interPreComment;
    public:
        // Thiết lập tỉ lệ RR
        void RR(double riskReward)
        {
            if(riskReward > 0)
                m_riskReward = riskReward;
        }
        void LotChain(string lotChain)
        {
            m_lotChain = lotChain;
        }
        void ExpectProfit(double expectProfit)
        {
            m_expectProfit = expectProfit;
        }
        // Thiết lập ghi chú khi tạo lệnh
        void SetAppendComment(string appendComment)
        {
            m_appendComment = appendComment;
        }
        // Thiết lập số dây lớn nhất
        void MaxWireHedge(int maxWireHedge)
        {
            if(maxWireHedge > 0)
                m_maxWireTotal = maxWireHedge;
        }
        void Disable(bool disable)
        {
            m_disabled = disable;
            if(disable)
                CloseAllPendingOrders();
        }
        bool Disable()
        {
            return m_disabled;
        }
        bool ExistWire()
        {
            return GetTicketByWireNumber(2) > 0;
        }
        void InternalComment(string comment)
        {
            m_interPreComment = comment;
        }
        // Khởi tạo các thông số cho đối tượng CHedge
        bool InitHedge(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       ulong magicNumber)
        {
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            m_magicNumber = magicNumber;
            
            m_reachMaxWire = false;
            m_disabled = false;
            return true;
        }
        string CombineComment()
        {
            return m_appendComment + "_" + m_interPreComment;
        }
        // ===================================
        // Xử lý chính
        // ===================================
        void Process(int limit)
        {
            if(m_disabled)
                return;
            
            ulong ticketLastWire = GetTicketLastWireHedge();
            if(ticketLastWire == 0)
            {
                // Close all left pending orders
                CloseAllPendingOrders();
                
                m_reachMaxWire = false;
                return;
                
            }
            
            // ================================================
            ulong ticketFirstOrder = GetTicketByWireNumber(1);
            int lastWireNumber = GetWireNumberHedge(ticketLastWire);
            
            if(lastWireNumber >= m_maxWireTotal)
            {
                // Đạt tới số dây max
                m_reachMaxWire = true;
            }
            
            // ==============================================
            // Xử lý tạo dây mới khi chưa đạt max dây [start]
            // ==============================================
            if(!m_reachMaxWire)
            {
                if(GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, CombineComment()) == 0
                   && GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, CombineComment()) == 0)
                {
                    int slPoint = GetSLByComment(ticketLastWire);
                    int tpPoint = GetTPByComment(ticketLastWire);
                    double lots = GetNextLot(lastWireNumber + 1);
                    double entry;
                    
                    // Tìm điểm vào lệnh đối xứng dựa vào lệnh đầu tiên
                    if(lastWireNumber == 1)
                    {
                        entry = GetSLPrice(ticketLastWire);
                        
                        // Lệnh đầu tiên không tồn tại SL, không xử lý!
                        if(entry == 0)
                            return;
                        
                        if(slPoint == 0)
                        {
                            slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - GetOpenPrice(GetTicketByWireNumber(1))));
                            tpPoint = (int)(slPoint * m_riskReward);
                        }
                    }
                    else
                    {
                        if(MathMod(lastWireNumber, 2) == 0)
                            entry = GetOpenPrice(GetTicketByWireNumber(1));
                        else
                            entry = GetOpenPrice(GetTicketByWireNumber(2));
                    }
                    
                    if(IsPositionSell(ticketLastWire))
                    {
                        m_trader.BuyStop(lots, entry, m_symbolCurrency, 0, 0, 0, 0, 
                                 CombineComment() + ";" 
                                 + PaddingLeft(lastWireNumber+1, 2, "0") + ";" + (string)slPoint + ";" + (string)tpPoint);
                    }
                    else
                    {
                        m_trader.SellStop(lots, entry, m_symbolCurrency, 0, 0, 0, 0, 
                                 CombineComment() + ";" 
                                 + PaddingLeft(lastWireNumber+1, 2, "0") + ";" + (string)slPoint + ";" + (string)tpPoint);
                    }
                    
                    // Gỡ SL của lệnh đầu tiên, phần còn lại EA sẽ quản lý
                    if(lastWireNumber == 1)
                    {
                        RemoveSL(ticketFirstOrder);
                    }
                    // Gỡ TP của lệnh đầu tiên nếu đã phát sinh dây mới
                    else if(lastWireNumber == 2)
                        RemoveTP(ticketFirstOrder);
                }
            }
            
            // ==============================================
            // Xử lý tạo dây mới khi chưa đạt max dây [end]
            // ==============================================
            
            // ==============================================
            // Xử lý khi đạt max dây [start]
            // ==============================================
            if(m_reachMaxWire)
            {
                bool hitSL = IsPositionHitSL(ticketLastWire);
                
                // Nếu dây cuối cùng chạm SL -> đóng lệnh
                if(hitSL)
                {
                    // Nếu sau khi đóng lệnh mà còn lại chỉ 1 dây đầu tiên duy nhất
                    // -> Cập nhật SL và TP cho sàn tự làm việc, EA không cần can thiệp
                    double sl, tp;
                    if(lastWireNumber == 2)
                    {
                        sl = GetOpenPrice(ticketLastWire);
                        double firstOrderOpenPrice = GetOpenPrice(ticketFirstOrder);
                        if(IsPositionSell(ticketFirstOrder))
                        {
                            tp = firstOrderOpenPrice - MathAbs(firstOrderOpenPrice - sl)*m_riskReward;
                            UpdateSLTP(GetTicketByWireNumber(1), sl, tp);
                        }
                        else
                        {
                            tp = firstOrderOpenPrice + MathAbs(firstOrderOpenPrice - sl)*m_riskReward;
                            UpdateSLTP(GetTicketByWireNumber(1), sl, tp);
                        }
                    }
                    
                    // Đóng lệnh
                    m_trader.PositionClose(ticketLastWire);
                    return;
                }
            }
            // ==============================================
            // Xử lý khi đạt max dây [end]
            // ==============================================
            
            // ==============================================
            // Xử lý khi đạt profit [start]
            // ==============================================
            double totalProfit = GetTotalProfit();
            bool reachProfit = false;
            
            // Chỗ này có thể tùy chỉnh giá trị 0 bằng profit cụ thể
            // Có thể định nghĩa bằng tham số đầu vào
            reachProfit = totalProfit > m_expectProfit;
            
            
            if(reachProfit)
            {
                CPositionInfo pos;
                if(pos.SelectByTicket(ticketLastWire))
                    if(pos.TakeProfit() > 0 && lastWireNumber == 1)
                        return;
                    else;
                else
                    return;
                
                CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, 
                                         m_appendComment + ";01");
                CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, 
                                         CombineComment());
                CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, 
                                     m_appendComment + ";01");
                CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, 
                                     CombineComment());
                //for(int idx = GetWireNumberHedge(ticketLastWire); idx >= 1; idx--)
                //{
                //    CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, 
                //                         m_appendComment
                //                         + ";" + PaddingLeft(idx, 2, "0"));
                //    CloseAllSellPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, 
                //                         m_appendComment
                //                         + ";" + PaddingLeft(idx, 2, "0"));
                //}
                m_reachMaxWire = false;
                
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, 
                                   CombineComment());
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, 
                                   CombineComment());
                
                return;
            }
            // ==============================================
            // Xử lý khi đạt profit [end]
            // ==============================================
        }
    protected:
        // ===================================
        // Lấy thông tin lot tiếp theo
        // ===================================
        double GetNextLot(int wire)
        {
            if(wire <= 0)
                return 0;
            string lots[];
            Split(m_lotChain, ";", lots);
            if(ArraySize(lots) > wire)
                return (double)lots[wire-1];
            return 0;
        }
        
        // ===================================
        // Đóng toàn bộ lệnh chờ SELL và BUY
        // ===================================
        void CloseAllPendingOrders()
        {
            for(int idxWire = 2; idxWire <= m_maxWireTotal; idxWire++)
            {
                ClosePendingBuy(idxWire);
                ClosePendingSell(idxWire);
            }
        }
        
        // ===================================
        // Đóng toàn bộ lệnh chờ BUY STOP
        // ===================================
        void ClosePendingBuy(int wire)
        {
            if(GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, 
                                      ORDER_TYPE_BUY_STOP, 
                                      CombineComment() + ";" + PaddingLeft(wire, 2, "0")) > 0)
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, 
                                   ORDER_TYPE_BUY_STOP, 
                                   CombineComment() + ";" + PaddingLeft(wire, 2, "0"));
        }
        // ===================================
        // Đóng toàn bộ lệnh chờ SELL STOP
        // ===================================
        void ClosePendingSell(int wire)
        {
            if(GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, 
                                      ORDER_TYPE_SELL_STOP, 
                                      CombineComment() + ";" + PaddingLeft(wire, 2, "0")) > 0)
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, 
                                   ORDER_TYPE_SELL_STOP, 
                                   CombineComment() + ";" + PaddingLeft(wire, 2, "0"));
        }
        
        // ===================================
        // Gỡ bỏ TP của lệnh
        // ===================================
        bool RemoveTP(ulong ticket)
        {
            CPositionInfo pos;
            if(pos.SelectByTicket(ticket))
            {
                double sl = pos.StopLoss();
                double tp = pos.TakeProfit();
                if(tp > 0)
                    return m_trader.PositionModify(ticket, sl, 0);
            }
            return false;
        }
        
        // ===================================
        // Gỡ bỏ SL của lệnh
        // ===================================
        bool RemoveSL(ulong ticket)
        {
            CPositionInfo pos;
            if(pos.SelectByTicket(ticket))
            {
                double sl = pos.StopLoss();
                double tp = pos.TakeProfit();
                if(sl > 0)
                    return m_trader.PositionModify(ticket, 0, tp);
            }
            return false;
        }
        
        // ===================================
        // Tinh tổng lợi nhuận bao gồm bù trừ phí swap
        // ===================================
        double GetTotalProfit()
        {
            string commentContain = m_appendComment;
            double sumProfit = 0;
        
            for(int i=PositionsTotal()-1; i>=0; i--) {
                string CounterSymbol=PositionGetSymbol(i);
                ulong ticket = PositionGetTicket(i);
        
                if(PositionSelectByTicket(ticket)) {
                    if(m_symbolCurrency == CounterSymbol
                            && PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                        string comment = PositionGetString(POSITION_COMMENT);
                        if(StringFind(comment, commentContain) >= 0) 
                        {
                            sumProfit += PositionGetDouble(POSITION_PROFIT);
                            sumProfit += PositionGetDouble(POSITION_SWAP);
                        }
                    }
                }
            }
            return sumProfit;
        }
        
        // =====================================
        // Kiểm tra ticket có chạm SL ?
        // =====================================
        bool IsPositionHitSL(ulong ticket)
        {
            int wireHedge = GetWireNumberHedge(ticket);
            if(wireHedge == 1)
                return false;

            ulong preTicket = GetTicketByWireNumber(wireHedge - 1);
            
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            //double profit = pos.Profit();
            ENUM_POSITION_TYPE posType = pos.PositionType();
            
            //double openPrice = pos.PriceOpen();
            double currentPrice = pos.PriceCurrent();
            double sl = GetOpenPrice(preTicket);
            
            if(posType == POSITION_TYPE_SELL)
            {
                if(currentPrice >= sl)
                {
                    Print("**** Hit SL ****");
                    return true;
                }
            }
            else if(posType == POSITION_TYPE_BUY)
            {
                if(currentPrice <= sl)
                {
                    Print("**** Hit SL ****");
                    return true;
                }
            }
            return false;
        }
        
        // =====================================
        // Kiểm tra ticket có chạm TP ?
        // =====================================
        bool IsPositionHitTP(ulong ticket)
        {
            int wireHedge = GetWireNumberHedge(ticket);
            if(wireHedge == 1)
                return false;
            
            ulong preTicket = GetTicketByWireNumber(wireHedge - 1);
            
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            //double profit = pos.Profit();
            ENUM_POSITION_TYPE posType = pos.PositionType();
            
            double openPrice = pos.PriceOpen();
            double currentPrice = pos.PriceCurrent();
            double sl = GetOpenPrice(preTicket);
            
            if(posType == POSITION_TYPE_SELL)
            {
                double tp = openPrice - MathAbs(openPrice - sl)*m_riskReward;
                if(currentPrice <= tp)
                {
                    return true;
                }
            }
            else if(posType == POSITION_TYPE_BUY)
            {
                double tp = openPrice + MathAbs(openPrice - sl)*m_riskReward;
                if(currentPrice >= tp)
                {
                    return true;
                }
            }
            return false;
        }
        
        // =====================================
        // Lấy số dây dựa trên ticket
        // =====================================
        int GetWireNumberHedge(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            //double profit = pos.Profit();
            ENUM_POSITION_TYPE posType = pos.PositionType();
            
            double openPrice = pos.PriceOpen();
            double currentPrice = pos.PriceCurrent();
            
            string comment = pos.Comment();
            string comments[];
            Split(comment, ";", comments);
            int len = ArraySize(comments);
            if(ArraySize(comments) > 1)
            {
                int wireNumber = (int)(StringToInteger(comments[1]));
                return wireNumber;
            }
            return 0;
        }
        
        // =====================================
        // Lấy thông tin giá đặt lệnh của ticket
        // =====================================
        double GetOpenPrice(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            double price = pos.PriceOpen();
            return price;
        }
        // =====================================
        // Lấy thông tin profit của ticket
        // =====================================
        double GetProfit(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            double profit = pos.Profit() + pos.Swap();
            return profit;
        }
        // =====================================
        // Lấy thông tin SL của ticket
        // =====================================
        double GetSLPrice(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            double price = pos.StopLoss();
            return price;
        }
        // =====================================
        // Lấy thông tin TP của ticket
        // =====================================
        double GetTPPrice(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            double price = pos.TakeProfit();
            return price;
        }
        // =====================================
        // Lấy thông tin SL của ticket dựa vào ghi chú
        // =====================================
        int GetTPByComment(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            string comment = pos.Comment();
            string comments[];
            Split(comment, ";", comments);
            if(ArraySize(comments) <= 3)
                return 0;
                
            int tp = (int)(StringToInteger(comments[3]));
            return tp;
        }
        // =====================================
        // Lấy thông tin SL của ticket dựa vào ghi chú
        // =====================================
        int GetSLByComment(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            string comment = pos.Comment();
            string comments[];
            Split(comment, ";", comments);
            if(ArraySize(comments) <= 2)
                return 0;
                
            int sl = (int)(StringToInteger(comments[2]));
            return sl;
        }
        // =====================================
        // Lấy thông tin khối lượng (lot) của ticket
        // =====================================
        double GetVol(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            
            double vol = pos.Volume();
            return vol;
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
        
        // =====================================
        // Cập nhật SL và TP cho lệnh (theo ticket) sử dụng thông tin từ ghi chú của lệnh đó
        // =====================================
        bool UpdateSLTPByCommentItself(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            ENUM_POSITION_TYPE posType = pos.PositionType();
                       
            string comment = pos.Comment();
            string comments[];
            Split(comment, ";", comments);
            if(ArraySize(comments) <= 3)
                return false;
                
            int tpPoints = (int)(StringToInteger(comments[3]));
            int slPoints = (int)(StringToInteger(comments[2]));
            double sl = 0, tp = 0;
            if(pos.StopLoss() == 0)
            {
                if(posType == POSITION_TYPE_BUY)
                    sl = pos.PriceOpen() - PointsToPriceShift(m_symbolCurrency, slPoints);
                else
                    sl = pos.PriceOpen() + PointsToPriceShift(m_symbolCurrency, slPoints);
            }
            else
                sl = pos.StopLoss();
                
            if(pos.TakeProfit() == 0)
            {
                if(posType == POSITION_TYPE_BUY)
                    tp = pos.PriceOpen() + PointsToPriceShift(m_symbolCurrency, slPoints*m_riskReward);
                else
                    tp = pos.PriceOpen() - PointsToPriceShift(m_symbolCurrency, slPoints*m_riskReward);
            }
            else
                tp = pos.TakeProfit();
            return m_trader.PositionModify(ticket, sl, tp);
        }
        
        // =====================================
        // Kiểm tra ticket là loại SELL ?
        // =====================================
        int IsPositionSell(ulong ticket)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            //double profit = pos.Profit();
            ENUM_POSITION_TYPE posType = pos.PositionType();
            return posType == POSITION_TYPE_SELL;
        }
        
        // =====================================
        // Lấy thông tin ticket dựa trên số dây
        // =====================================
        ulong GetTicketByWireNumber(int wire)
        {
            string searchComment = m_appendComment + ";01;";
            ulong outTickets[];
            if(wire > 1)
                searchComment = CombineComment() + ";" + PaddingLeft(wire, 2, "0");
            if(SearchPendingPosition(m_symbolCurrency, m_magicNumber, 
                                     searchComment, true, true, outTickets) > 0)
                return outTickets[0];
            
            return 0;
        }
        
        // =====================================
        // Lấy thông tin ticket của dây cuối cùng
        // =====================================
        ulong GetTicketLastWireHedge()
        {
            //string commentContain = m_appendComment;
                
            ulong ticketResult = 0;
            string lastComment = "";
            
            for(int i=PositionsTotal()-1; i>=0; i--)
            {
                string CounterSymbol=PositionGetSymbol(i);
                ulong ticket = PositionGetTicket(i);
                if(PositionSelectByTicket(ticket))
                {
                    if(m_symbolCurrency == CounterSymbol 
                       && PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
                    {
                        string comment = PositionGetString(POSITION_COMMENT);
                        
                        string initComment = m_appendComment + ";01;";
                        string wireComment = CombineComment();
                        if(StringFind(comment, initComment) >= 0)
                        {
                            if(ticketResult == 0)
                            {
                                ticketResult = ticket;
                                lastComment = comment;
                            }
                        }
                        else if(StringFind(comment, wireComment) >= 0)
                        {
                            if(ticketResult == 0)
                            {
                                ticketResult = ticket;
                                lastComment = comment;
                            }
                            else
                            {
                                if(lastComment < comment)
                                {
                                    ticketResult = ticket;
                                    lastComment = comment;
                                }
                            }
                        }
                    }
                }
            }
            return ticketResult;
        }
        
};