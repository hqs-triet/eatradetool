
#include <Trade\PositionInfo.mqh>
#include  "ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"

// ============================================
// Class thể hiện phương pháp "Grid"
// ============================================
class CGrid
{
    private:
        // -------------------------------------
        // Khai báo chung
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        string m_appendComment;
        int m_magicNumber;
        string m_interPreComment;
        bool m_disabled;
        
        // -------------------------------------
        int m_zoneGrid, m_step;
        double m_ratioTP;
        
    public:
        
        // Thiết lập ghi chú khi tạo lệnh
        void SetAppendComment(string appendComment)
        {
            m_appendComment = appendComment;
        }
        void InternalComment(string comment)
        {
            m_interPreComment = comment;
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
                       int magicNumber)
        {
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            m_magicNumber = magicNumber;

            m_disabled = false;
            return true;
        }
        
        // ===================================
        // Xử lý chính
        // ===================================
        void Process(int limit)
        {
            if(m_disabled)
                return;
            
            int countPost = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_appendComment);
            

        }
    protected:
        string CombineComment()
        {
            return m_appendComment + "_" + m_interPreComment;
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
        // ===================================
        // Đóng toàn bộ lệnh chờ SELL và BUY
        // ===================================
        void CloseAllPendingOrders()
        {
            string comment = CombineComment();
            ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, comment);
            ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, comment);
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
        
        
};