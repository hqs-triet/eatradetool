
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "..\PriceAction.mqh"
#include  "IAlgorithm.mqh"
#include  "..\..\libs\Condition\DoubleTopPoints.mqh"
#include  "..\..\libs\Condition\DoubleBottomPoints.mqh"
#include  "..\..\libs\Indicator\Rsi.mqh"

enum ENUM_DoubleTopBottom_Entry
{
    DoubleTopBottom_Back1Part4_Neckline = 1, // Cách 1/4 chiều cao (đỉnh/đáy vs neckline)
    DoubleTopBottom_Back1Part3_Neckline = 2, // Cách 1/3 chiều cao (đỉnh/đáy vs neckline)
    DoubleTopBottom_Back1Part2_Neckline = 4,  // Cách 1/2 chiều cao (đỉnh/đáy vs neckline)
    DoubleTopBottom_Back_Neckline = 8,        // Giá tại neckline
    DoubleTopBottom_Back3Part4_Neckline = 16, // Cách 3/4 chiều cao (đỉnh/đáy vs neckline)
    DoubleTopBottom_BackPoints_Neckline = 32  // Giá lùi một đoạn points từ neckline
};
// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input group "Mô hình 2 đỉnh/đáy - Thiết lập chung"
input int InpDoubleTopBottom_Zone = 300; // Vùng kiểm tra 2 đỉnh liền kề
input int InpDoubleTopBottom_Period = 200;  // Giai đoạn kiểm tra
input int InpDoubleTopBottom_Depth = 20;  // Độ sâu kiểm tra đỉnh đáy (zigzag)
input int InpDoubleTopBottom_MinPeriod2TopBottom = 40; // Khoảng cách tối thiểu giữa 2 đỉnh
input bool InpDoubleTopBottom_Trailing = true;  // Tối ưu hóa lợi nhuận

input group "Điều kiện vào lệnh"
input ENUM_DoubleTopBottom_Entry InpDoubleTopBottom_EntryType = DoubleTopBottom_BackPoints_Neckline; // Lùi một khoảng cách tính từ neckline
input int InpDoubleTopBottom_EntryTypePoints = 100; // |- Số points lùi lại từ neckline (nếu chọn points)
input double InpDoubleTopBottom_RatioTPVsSL = 1.5; // Tính TP so với SL

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CDoubleTopBottom: public IAlgorithm
{
    private:
        double m_lot;
        
        CDoubleTopPoints m_doubleTopPoints;
        CDoubleBottomPoints m_doubleBottomPoints;
        CRsi m_rsi;
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
            
            if(m_doubleTopPoints.Init(m_symbolCurrency, m_tf, m_infoCurrency, 
                           InpDoubleTopBottom_Zone, InpDoubleTopBottom_Period, InpDoubleTopBottom_Depth, 
                           InpDoubleTopBottom_MinPeriod2TopBottom) == INIT_FAILED)
                return false;
            if(m_doubleBottomPoints.Init(m_symbolCurrency, m_tf, m_infoCurrency, 
                           InpDoubleTopBottom_Zone, InpDoubleTopBottom_Period, InpDoubleTopBottom_Depth, 
                           InpDoubleTopBottom_MinPeriod2TopBottom) == INIT_FAILED)
                return false;

            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            // Xử lý điều kiện
            m_doubleTopPoints.Process(limit);
            m_doubleBottomPoints.Process(limit);
            
            // Trailing
            if(InpDoubleTopBottom_Trailing)
                TrailingStopByComment(m_symbolCurrency, m_magicNumber, m_trader, 5, true, true, m_prefixComment);
            
            
            if(m_doubleTopPoints.IsMatched(limit, 0))
            {
                double topPrice = m_doubleTopPoints.TopPointPrice();
                double neckPrice = m_doubleTopPoints.NecklinePrice();
                
                int totalPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
                int totalPending = GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment);
                if(totalPending == 0
                   && totalPos == 0)
                {
                    datetime currTime = TimeCurrent();
                    datetime expTime = currTime + 3600 * 250; // 250 giờ
                    
                    double entry = neckPrice + PointsToPriceShift(m_symbolCurrency, InpDoubleTopBottom_EntryTypePoints);
                    if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back_Neckline)
                        entry = neckPrice;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back1Part2_Neckline)
                        entry = neckPrice + MathAbs(topPrice - neckPrice) / 2;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back1Part3_Neckline)
                        entry = neckPrice + MathAbs(topPrice - neckPrice) / 3;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back1Part4_Neckline)
                        entry = neckPrice + MathAbs(topPrice - neckPrice) / 4;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back3Part4_Neckline)
                        entry = neckPrice + 3 * MathAbs(topPrice - neckPrice) / 4;
                    
                    double sl = topPrice + PointsToPriceShift(m_symbolCurrency, 50);
                    double tp = entry - MathAbs(entry - sl) * InpDoubleTopBottom_RatioTPVsSL;
                    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                    string comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    Print("Mô hình hai đỉnh! -> SELL LIMIT at " + entry);
                    m_trader.SellLimit(m_lot, entry , m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expTime, comment);
                }
            }
            
//            if(m_doubleTopPoints.HasSignalMatched(limit, 0))
//            {
//                double topPrice = m_doubleTopPoints.TopPointPrice();
//                double neckPrice = m_doubleTopPoints.NecklinePrice();
//                if(m_infoCurrency.close(1) > neckPrice
//                   && IsCandleDown(1, m_infoCurrency)
//                   )
//                {
//                    int totalPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
//                    int totalPending = GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment);
//                    if(totalPending == 0
//                       && totalPos == 0)
//                    {
//                        double entry = topPrice;
//                        
//                        double sl = topPrice + PointsToPriceShift(m_symbolCurrency, 100);
//                        double tp = neckPrice;
//                        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
//                        int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
//                        string comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
//                        
//                        Print("Mô hình hai đỉnh! -> SELL at " + entry);
//                        m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment);
//                    }
//                }
//            }
            
            if(m_doubleBottomPoints.IsMatched(limit, 0))
            {
                double bottomPrice = m_doubleBottomPoints.BottomPointPrice();
                double neckPrice = m_doubleBottomPoints.NecklinePrice();

                int totalPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
                int totalPending = GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment);
                if(totalPending == 0
                   && totalPos == 0)
                {
                    // Thời gian hết hạn của lệnh
                    datetime currTime = TimeCurrent();
                    datetime expTime = currTime + 3600 * 250;   // 250 giờ
                    
                    double entry = neckPrice - PointsToPriceShift(m_symbolCurrency, InpDoubleTopBottom_EntryTypePoints);
                    if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back_Neckline)
                        entry = neckPrice;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back1Part2_Neckline)
                        entry = neckPrice - MathAbs(bottomPrice - neckPrice) / 2;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back1Part3_Neckline)
                        entry = neckPrice - MathAbs(bottomPrice - neckPrice) / 3;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back1Part4_Neckline)
                        entry = neckPrice - MathAbs(bottomPrice - neckPrice) / 4;
                    else if(InpDoubleTopBottom_EntryType == DoubleTopBottom_Back3Part4_Neckline)
                        entry = neckPrice - 3 * MathAbs(bottomPrice - neckPrice) / 4;
                        
                    double sl = bottomPrice - PointsToPriceShift(m_symbolCurrency, 50);
                    double tp = entry + MathAbs(entry - sl) * InpDoubleTopBottom_RatioTPVsSL;
                    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                    string comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    Print("Mô hình hai đáy! -> BUY LIMIT at " + entry);
                    m_trader.BuyLimit(m_lot, entry , m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expTime, comment);
                }
            }

//            if(m_doubleBottomPoints.HasSignalMatched(limit, 0))
//            {
//                double bottomPrice = m_doubleBottomPoints.BottomPointPrice();
//                double neckPrice = m_doubleBottomPoints.NecklinePrice();
//                if(m_infoCurrency.close(1) < neckPrice
//                   && IsCandleUp(1, m_infoCurrency)
//                   )
//                {
//                    int totalPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
//                    int totalPending = GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment);
//                    if(totalPending == 0
//                       && totalPos == 0)
//                    {
//                        double entry = bottomPrice;
//                        
//                        double sl = bottomPrice - PointsToPriceShift(m_symbolCurrency, 100);
//                        double tp = neckPrice;
//                        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
//                        int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
//                        string comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
//                        
//                        Print("Mô hình hai đáy! -> BUY at " + entry);
//                        m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment);
//                    }
//                }
//            }
            
        }
};