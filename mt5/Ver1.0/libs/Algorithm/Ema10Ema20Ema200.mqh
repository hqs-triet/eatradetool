
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpEma10Ema20Ema200TpRatio = 1.2;  // |- Tỉ lệ TP so với SL
input int    InpEma10Ema20Ema200SLMinPoint = 150; // |- Số point nhỏ nhất của SL
input int    InpEma10Ema20Ema200SLMaxPoint = 500; // |- Số point lớn nhất của SL
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CEma10Ema20Ema200: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_ema10Buffer[], m_ema20Buffer[], m_ema200Buffer[];
        int m_ema10Handler, m_ema20Handler, m_ema200Handler;
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
            
            // EMA10
            ArraySetAsSeries(m_ema10Buffer, true);
            m_ema10Handler = iMA(m_symbolCurrency, m_tf, 10, 0, MODE_EMA, PRICE_CLOSE);
            
            // EMA20
            ArraySetAsSeries(m_ema20Buffer, true);
            m_ema20Handler = iMA(m_symbolCurrency, m_tf, 20, 0, MODE_EMA, PRICE_CLOSE);
            
            // EMA200
            ArraySetAsSeries(m_ema200Buffer, true);
            m_ema200Handler = iMA(m_symbolCurrency, m_tf, 200, 0, MODE_EMA, PRICE_CLOSE);
            
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_ema10Handler, 0, 0, bars, m_ema10Buffer);
            CopyBuffer(m_ema20Handler, 0, 0, bars, m_ema20Buffer);
            CopyBuffer(m_ema200Handler, 0, 0, bars, m_ema200Buffer);
            
            int slPoints = 0, tpPoints = 0;
            double sl, tp;
            string comment = "";

            MqlDateTime currTime;
            TimeToStruct(TimeCurrent(), currTime);
            if(currTime.hour <= 7 || currTime.hour >= 20)
                return;
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                // SELL
                if(m_infoCurrency.close(1) < m_ema200Buffer[1]
                   && m_ema10Buffer[1] < m_ema200Buffer[1]
                   && m_ema20Buffer[1] < m_ema200Buffer[1]
                   && m_ema10Buffer[2] > m_ema20Buffer[2]
                   && m_ema10Buffer[1] < m_ema20Buffer[1])
                {
                    sl = m_ema200Buffer[1];
                    
                    double entry = m_infoCurrency.bid();
                    tp = entry - MathAbs(sl - entry) * InpEma10Ema20Ema200TpRatio;
                    
                    slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                    if(slPoints > InpEma10Ema20Ema200SLMaxPoint || slPoints < InpEma10Ema20Ema200SLMinPoint)
                        return;
                    tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                    comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    m_trader.Sell(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                }
                
                // BUY
                if(m_infoCurrency.close(1) > m_ema200Buffer[1]
                   && m_ema10Buffer[1] > m_ema200Buffer[1]
                   && m_ema20Buffer[1] > m_ema200Buffer[1]
                   && m_ema10Buffer[2] < m_ema20Buffer[2]
                   && m_ema10Buffer[1] > m_ema20Buffer[1])
                {
                    sl = m_ema200Buffer[1];
                    
                    double entry = m_infoCurrency.ask();
                    tp = entry + MathAbs(sl - entry) * InpEma10Ema20Ema200TpRatio;
                    slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                    if(slPoints > InpEma10Ema20Ema200SLMaxPoint || slPoints < InpEma10Ema20Ema200SLMinPoint)
                        return;
                    tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                    comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    m_trader.Buy(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                }
            }
            
        }
};