
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input int    InpPullbackOsMASLDistancePlus = 150;          // Khoảng cách SL cộng thêm
input double InpPullbackOsMATPRatio = 1.5;                  // Tỉ lệ TP so với SL
input bool  InpPullbackOsMALimitTradeTime = true;     // Chỉ định thời gian giao dịch?
input uint   InpPullbackOsMALimitTradeTimeStart = 13;  // |- Thời gian giao dịch >= Giờ bắt đầu
input uint   InpPullbackOsMALimitTradeTimeEnd = 23;    // |- Thời gian giao dịch < Giở kết thúc
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade cho chiến thuật pullback của OsMA
// ===================================================================
class CPullbackOsMA: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_ema20Buffer[], m_ema34Buffer[], m_ema50Buffer[], m_ema200Buffer[], m_osmaBuffer[];
        int m_ema20Handler, m_ema34Handler, m_ema50Handler, m_ema200Handler, m_osmaHandler;
        int m_count;
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
            
            // EMA20, EMA34, EMA50, EMA200
            ArraySetAsSeries(m_ema20Buffer, true);
            ArraySetAsSeries(m_ema34Buffer, true);
            ArraySetAsSeries(m_ema50Buffer, true);
            ArraySetAsSeries(m_ema200Buffer, true);
            m_ema20Handler = iMA(m_symbolCurrency, m_tf, 20, 0, MODE_EMA, PRICE_CLOSE);
            m_ema34Handler = iMA(m_symbolCurrency, m_tf, 34, 0, MODE_EMA, PRICE_CLOSE);
            m_ema50Handler = iMA(m_symbolCurrency, m_tf, 50, 0, MODE_EMA, PRICE_CLOSE);
            m_ema200Handler = iMA(m_symbolCurrency, m_tf, 200, 0, MODE_EMA, PRICE_CLOSE);
            
            // OsMA
            ArraySetAsSeries(m_osmaBuffer, true);
            m_osmaHandler = iOsMA(m_symbolCurrency, m_tf, 12, 26, 9, PRICE_CLOSE);
            
            // For test
            iRSI(m_symbolCurrency, m_tf, 14, PRICE_CLOSE);
            iStochastic(m_symbolCurrency, m_tf, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
            
            m_lot = 0.01;
            m_count = 0;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            if(limit <= 0)
                return;
            
            if(m_count > 0)
            {
                m_count--;
                return;
            }
            
            if(InpPullbackOsMALimitTradeTime)
            {
                MqlDateTime currTime;
                TimeToStruct(TimeCurrent(), currTime);
                if(currTime.hour < InpPullbackOsMALimitTradeTimeStart 
                   || currTime.hour >= InpPullbackOsMALimitTradeTimeEnd)
                    return;
            }
            // Cập nhật tín hiệu mới nhất
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            // Cập nhật giá trị mới nhất của OsMA, EMA20/34/50/200
            CopyBuffer(m_osmaHandler, 0, 0, bars, m_osmaBuffer);
            CopyBuffer(m_ema20Handler, 0, 0, bars, m_ema20Buffer);
            CopyBuffer(m_ema34Handler, 0, 0, bars, m_ema34Buffer);
            CopyBuffer(m_ema50Handler, 0, 0, bars, m_ema50Buffer);
            CopyBuffer(m_ema200Handler, 0, 0, bars, m_ema200Buffer);
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                bool hasNewPos = false;
                // Trường hợp BUY
                hasNewPos = hasNewPos || ProcessBuy();
                
                // Trường hợp SELL
                hasNewPos = hasNewPos || ProcessSell();
                
                if(hasNewPos)
                {
                    m_count = 10;
                }
            }
        }
    private:
        // ---------------------------------------------------
        // Xử lý cho trường hợp BUY
        // ---------------------------------------------------
        bool ProcessBuy() 
        {
            if(   m_ema20Buffer[1] > m_ema34Buffer[1]
               && m_ema34Buffer[1] > m_ema50Buffer[1]
               && m_ema50Buffer[1] > m_ema200Buffer[1]
               && m_osmaBuffer[1]  < 0 && m_osmaBuffer[1] > m_osmaBuffer[2] 
               && m_osmaBuffer[2] < m_osmaBuffer[3] 
               && m_osmaBuffer[3] < m_osmaBuffer[4] && m_osmaBuffer[4] < 0
               && m_infoCurrency.close(1) > m_ema20Buffer[1]
               && m_infoCurrency.low(1) > m_infoCurrency.low(2)
               )
            {
                double entry = m_infoCurrency.ask();
                double lowestPrice = GetMinPriceRange(m_infoCurrency, 1, 5, true);
                double sl = lowestPrice - PointsToPriceShift(m_symbolCurrency, InpPullbackOsMASLDistancePlus);
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                int tpPoints = slPoints * InpPullbackOsMATPRatio;
                double tp = entry + PointsToPriceShift(m_symbolCurrency, tpPoints);
                string comment = m_prefixComment + ";" + slPoints + ";" + tpPoints;
                
                return m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment);
            }
            return false;
        }
        
        // ---------------------------------------------------
        // Xử lý cho trường hợp SELL
        // ---------------------------------------------------
        bool ProcessSell() 
        {
            if(   m_ema20Buffer[1] < m_ema34Buffer[1]
               && m_ema34Buffer[1] < m_ema50Buffer[1]
               && m_ema50Buffer[1] < m_ema200Buffer[1]
               && m_osmaBuffer[1]  > 0 && m_osmaBuffer[1] < m_osmaBuffer[2]
               && m_osmaBuffer[2] > m_osmaBuffer[3] 
               && m_osmaBuffer[3] > m_osmaBuffer[4] && m_osmaBuffer[4] > 0
               && m_infoCurrency.close(1) < m_ema20Buffer[1]
               && m_infoCurrency.high(1) < m_infoCurrency.high(2)
               )
            {
                double entry = m_infoCurrency.bid();
                double highestPrice = GetMaxPriceRange(m_infoCurrency, 1, 5, true);
                double sl = highestPrice + PointsToPriceShift(m_symbolCurrency, InpPullbackOsMASLDistancePlus);
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                int tpPoints = slPoints * InpPullbackOsMATPRatio;
                double tp = entry - PointsToPriceShift(m_symbolCurrency, tpPoints);
                string comment = m_prefixComment + ";" + slPoints + ";" + tpPoints;
                
                return m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment);
            }
            return false;
        }
};