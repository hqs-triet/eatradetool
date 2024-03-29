
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#include  "..\..\libs\Condition\ResSup.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input group "Kháng cự/hỗ trợ - Thiết lập chung"
input int InpResSup_Period = 200;   // Giai đoạn kiểm tra
input int InpResSup_Depth = 12;     // Độ sâu kiểm tra đỉnh đáy (zigzag)
input int InpResSup_MinPeriod = 20; // Khoảng cách tối thiểu để tìm kháng cự/hỗ trợ
input int InpResSup_Zone = 100;     // Vùng kiểm tra kháng cự/hỗ trợ

input group "Thiết lập giao dịchh"
input int InpResSup_EntryShift = 100; // Mở lệnh LIMIT cách 1 đoạn so với giá hiện tại
input int InpResSup_SL = 500;         // SL (points)
input double InpResSup_TPRatio = 3;   // TP (theo tỉ lệ với SL)
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo kháng cự/hỗ trợ, thừa kế IAlgorithm
// ===================================================================
class CResSupTrade: public IAlgorithm
{
    private:
        double m_lot;
        CResSup m_resSup;
        int m_slPoints;
    public:
        void Vol(double vol)
        {
            m_lot = vol;
        }
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       string prefixComment, int magicNumber)
        {
            IAlgorithm::Init(symbol, tf, trader, infoCurrency, prefixComment, magicNumber);
            
            // Khởi tạo đối tượng xử lý kháng cự/hỗ trợ
            if(m_resSup.Init(m_symbolCurrency, m_tf, m_infoCurrency, 
                           InpResSup_Period, InpResSup_Depth, InpResSup_MinPeriod, InpResSup_Zone) == INIT_FAILED)
                return false;

            m_lot = 0.01;
            m_slPoints = InpResSup_SL;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            MoveSLToEntryByProfitVsSL(m_symbolCurrency, m_magicNumber, 1, m_trader, 5, true, true, m_prefixComment);
            //TrailingStopByComment(m_symbolCurrency, m_magicNumber, m_trader, 5, true, true, m_prefixComment);
            
            if(limit <= 0)
                return;
            
            // Xử lý điều kiện
            m_resSup.Process(limit);
            
            // Phát hiện kháng cự/hỗ trợ
            if(m_resSup.IsMatched(limit, ENUM_RESSUP_RESISTANCE)
               || m_resSup.IsMatched(limit, ENUM_RESSUP_SUPPORT))
            {
                if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0
                   && GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment) == 0
                   && GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment) == 0
                   )
                {
                    // Thời gian hết hạn của lệnh
                    datetime currTime = TimeCurrent();
                    datetime expTime = currTime + 3600 * 50; // tính theo giờ, vd: 50 giờ
                    double tpRatio = InpResSup_TPRatio;
                    // Sell
                    if(m_resSup.SuggestSell())
                    {
                        double entry = m_infoCurrency.ask() + PointsToPriceShift(m_symbolCurrency, InpResSup_EntryShift);
                        double sl = entry + PointsToPriceShift(m_symbolCurrency, m_slPoints);
                        double tp = entry - PointsToPriceShift(m_symbolCurrency, m_slPoints)*tpRatio;
                        string comment = m_prefixComment + ";001;" + m_slPoints + ";" + m_slPoints*tpRatio;
                        if(InpResSup_EntryShift != 0)
                            m_trader.SellLimit(m_lot, entry, m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expTime, comment);
                        else 
                            m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                    }
                    // Buy
                    else if(m_resSup.SuggestBuy())
                    {
                        double entry = m_infoCurrency.bid() - PointsToPriceShift(m_symbolCurrency, InpResSup_EntryShift);
                        double sl = entry - PointsToPriceShift(m_symbolCurrency, m_slPoints);
                        double tp = entry + PointsToPriceShift(m_symbolCurrency, m_slPoints)*tpRatio;
                        string comment = m_prefixComment + ";001;" + m_slPoints + ";" + m_slPoints*tpRatio;
                        if(InpResSup_EntryShift != 0)
                            m_trader.BuyLimit(m_lot, entry, m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expTime, comment);
                        else
                            m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                    }
                }
            }
        }
};