
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input int   InpMoMoSLDistance = 150;          // SL (point) cách EMA20
input int   InpMoMoSLTrailingDistance = 150;  // SL (point) di chuyển theo EMA20
input int   InpMoMoSLTrailingStep = 5;        // Bước di chuyển (point) của SL theo EMA20
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade MoMo, thừa kế IAlgorithm
// ===================================================================
class CMoMo: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_ema20Buffer[], m_osmaBuffer[];
        int m_ema20Handler, m_osmaHandler;
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
            
            // EMA20
            ArraySetAsSeries(m_ema20Buffer, true);
            m_ema20Handler = iMA(m_symbolCurrency, m_tf, 20, 0, MODE_EMA, PRICE_CLOSE);
            
            // OsMA
            ArraySetAsSeries(m_osmaBuffer, true);
            m_osmaHandler = iOsMA(m_symbolCurrency, m_tf, 12, 26, 9, PRICE_CLOSE);
            
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            // Cập nhật tín hiệu mới nhất
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                // Điều kiện vào lệnh khi qua nến mới
                if(limit > 0)
                {
                    // Cập nhật giá trị mới nhất của OsMA, EMA20
                    CopyBuffer(m_osmaHandler, 0, 0, bars, m_osmaBuffer);
                    CopyBuffer(m_ema20Handler, 0, 0, bars, m_ema20Buffer);
                    
                    bool hasNewPos = false;
                    // Trường hợp BUY
                    hasNewPos = hasNewPos || ProcessBuy();
                    
                    // Trường hợp SELL
                    hasNewPos = hasNewPos || ProcessSell();
                    
                    // Nếu thỏa điều kiện và mở lệnh, cần bật chế độ xử lý realtime để EA di chuyển SL theo EMA20
                    if(hasNewPos)
                        m_requireRealtime = true;
                }
            }
            else 
            {
                // Vì cần phải di chuyển SL dọc theo EMA20,
                // nên trường hợp này cần phải cập nhật giá trị mới liên tục cho EMA20
                CopyBuffer(m_ema20Handler, 0, 0, bars, m_ema20Buffer);
                
                // Xử lý di chuyển SL về hòa vốn nếu giá đi đúng hướng
                MoveSLToEntryByProfitVsSL(m_symbolCurrency, m_magicNumber, 1, 
                                        m_trader, InpMoMoSLTrailingStep, true, true, m_prefixComment);
                
                // Xử lý di chuyển SL dọc theo EMA20
                ProcessAdjustSLAlongEMA20();
            }
        }
    private:
        // ---------------------------------------------------
        // Xử lý cho trường hợp BUY
        // ---------------------------------------------------
        bool ProcessBuy() {
            // Điều kiện 1: OsMA chuyển thành dương
            // Lưu ý: xét giá trị của OsMA tới nến thứ 3
            if(m_osmaBuffer[1] > 0 && m_osmaBuffer[2] <= 0 && m_osmaBuffer[3] < 0)
            {
                // Điều kiện 2: nến tại vị trí 1 là nến tăng và giá close > EMA20
                if(IsCandleUp(1, m_infoCurrency) && m_infoCurrency.close(1) > m_ema20Buffer[1])
                {
                    // Điều kiện 3: trong phạm vi 5 nến (bao gồm nến vị trí 1), có nến cắt qua EMA20
                    if(   m_infoCurrency.low(1) < m_ema20Buffer[1]
                       || m_infoCurrency.low(2) < m_ema20Buffer[2]
                       || m_infoCurrency.low(3) < m_ema20Buffer[3]
                       || m_infoCurrency.low(4) < m_ema20Buffer[4]
                       || m_infoCurrency.low(5) < m_ema20Buffer[5])
                    {
                        int slPoints = 0, tpPoints = 0;
                        double sl, tp, entry;
                        string comment = "";
                        
                        // Lệnh BUY 1
                        entry = m_infoCurrency.ask();
                        sl = m_ema20Buffer[1] - PointsToPriceShift(m_symbolCurrency, InpMoMoSLDistance);
                        slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                        tp = entry + (entry - sl);
                        tpPoints = slPoints;
                        comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                        m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                        
                        // Lệnh BUY 2
                        comment = m_prefixComment + ";02;" + slPoints + ";0";
                        m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, 0, comment);
                        
                        return true;
                    }
                }
            }
            return false;
        }
        
        // ---------------------------------------------------
        // Xử lý cho trường hợp SELL
        // ---------------------------------------------------
        bool ProcessSell() {
            // Điều kiện 1: OsMA chuyển thành âm
            // Lưu ý: xét giá trị của OsMA tới nến thứ 3
            if(m_osmaBuffer[1] < 0 && m_osmaBuffer[2] >= 0 && m_osmaBuffer[3] > 0)
            {
                // Điều kiện 2: nến tại vị trí 1 là nến giảm và giá close < EMA20
                if(IsCandleDown(1, m_infoCurrency) && m_infoCurrency.close(1) < m_ema20Buffer[1])
                {
                    // Điều kiện 3: trong phạm vi 5 nến (bao gồm nến vị trí 1), có nến cắt qua EMA20
                    if(   m_infoCurrency.high(1) > m_ema20Buffer[1]
                       || m_infoCurrency.high(2) > m_ema20Buffer[2]
                       || m_infoCurrency.high(3) > m_ema20Buffer[3]
                       || m_infoCurrency.high(4) > m_ema20Buffer[4]
                       || m_infoCurrency.high(5) > m_ema20Buffer[5])
                    {
                        int slPoints = 0, tpPoints = 0;
                        double sl, tp, entry;
                        string comment = "";
                        
                        // Lệnh SELL 1
                        entry = m_infoCurrency.bid();
                        sl = m_ema20Buffer[1] + PointsToPriceShift(m_symbolCurrency, InpMoMoSLDistance);
                        slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                        tp = entry - (sl - entry);
                        tpPoints = slPoints;
                        comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                        m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                        
                        // Lệnh SELL 2
                        comment = m_prefixComment + ";02;" + slPoints + ";0";
                        m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, 0, comment);
                        
                        return true;
                    }
                }
            }
            return false;
        }
        
        // ---------------------------------------------------
        // Xử lý SL của lệnh BUY/SELL 2 di chuyển dọc theo EMA20
        // ---------------------------------------------------
        void ProcessAdjustSLAlongEMA20()
        {
            ulong outTickets[];
            string comment = m_prefixComment + ";02";
            int totalTargetPos = SearchActiveOpenPosition(m_symbolCurrency, 
                                                           m_magicNumber, comment, 
                                                           true, true, outTickets);
            if( totalTargetPos > 0)
            {
                for(int idx = totalTargetPos - 1; idx >= 0; idx--)
                {
                    // Lấy thông tin của position
                    CPositionInfo pos;
                    if(pos.SelectByTicket(outTickets[idx]))
                    {
                        bool isSellPos = pos.PositionType() == POSITION_TYPE_SELL;
                        double stepPriceShift = PointsToPriceShift(m_symbolCurrency, InpMoMoSLTrailingStep);
                        double slTrailingDistancePriceShift = PointsToPriceShift(m_symbolCurrency, InpMoMoSLTrailingDistance);
                        
                        // Trường hợp lệnh SELL 2
                        if(isSellPos)
                        {
                            // SL mới = cách EMA20 một khoảng cách chỉ định
                            double newSL = m_ema20Buffer[0] + slTrailingDistancePriceShift;
                            if(pos.StopLoss() > newSL + stepPriceShift
                               && ((MathAbs(pos.StopLoss() - pos.PriceOpen()) <= stepPriceShift)
                                    || pos.StopLoss() < pos.PriceOpen())
                               )
                            {
                                m_trader.PositionModify(outTickets[idx], newSL, pos.TakeProfit());
                            }
                        }
                        // Trường hợp lệnh BUY 2
                        else
                        {
                            // SL mới = cách EMA20 một khoảng cách chỉ định
                            double newSL = m_ema20Buffer[0] - slTrailingDistancePriceShift;
                            if(pos.StopLoss() < newSL - stepPriceShift
                               && ((MathAbs(pos.StopLoss() - pos.PriceOpen()) <= stepPriceShift)
                                    || pos.StopLoss() > pos.PriceOpen())
                               )
                            {
                                m_trader.PositionModify(outTickets[idx], newSL, pos.TakeProfit());
                            }
                        }
                    }
                }
                
            }
        }
};