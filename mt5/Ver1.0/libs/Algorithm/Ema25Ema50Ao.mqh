
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#resource "\\Indicators\\Examples\ZigZagColor.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpEma25Ema50AoTpRatio = 1.2;  // |- Tỉ lệ TP so với SL
input int    InpEma25Ema50AoSLBuffer = 20;  // |- Số point trừ hao của SL
input int    InpEma25Ema50AoSLMinPoint = 150; // |- Số point nhỏ nhất của SL
input int    InpEma25Ema50AoSLMaxPoint = 500; // |- Số point lớn nhất của SL
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Chiến thuật M5, M15: EMA25 cắt EMA50 kết hợp chỉ báo Awsome
// ===================================================================
class CEma25Ema50Ao: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_ema25Buffer[], m_ema50Buffer[], m_aoBuffer[], m_zigZagTopBuffer[], m_zigZagBottomBuffer[];
        int m_ema25Handler, m_ema50Handler, m_aoHandler, m_zigZagHandler;
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
            
            // EMA25
            ArraySetAsSeries(m_ema25Buffer, true);
            m_ema25Handler = iMA(m_symbolCurrency, m_tf, 25, 0, MODE_EMA, PRICE_CLOSE);
            
            // EMA50
            ArraySetAsSeries(m_ema50Buffer, true);
            m_ema50Handler = iMA(m_symbolCurrency, m_tf, 50, 0, MODE_EMA, PRICE_CLOSE);
            
            // Ao
            ArraySetAsSeries(m_aoBuffer, true);
            m_aoHandler = iAO(m_symbolCurrency, m_tf);
            
            // Zigzag
            ArraySetAsSeries(m_zigZagTopBuffer, true);
            ArraySetAsSeries(m_zigZagBottomBuffer, true);
            m_zigZagHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\Examples\\ZigZagColor",
                                         5,5,3
                                        );
                                        
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_ema25Handler, 0, 0, bars, m_ema25Buffer);
            CopyBuffer(m_ema50Handler, 0, 0, bars, m_ema50Buffer);
            CopyBuffer(m_aoHandler, 0, 0, bars, m_aoBuffer);
            CopyBuffer(m_zigZagHandler, 0, 0, bars, m_zigZagTopBuffer);
            CopyBuffer(m_zigZagHandler, 1, 0, bars, m_zigZagBottomBuffer);
            
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
                if(m_aoBuffer[1] < m_aoBuffer[2] && m_aoBuffer[2] < 0
                   && m_ema25Buffer[2] > m_ema50Buffer[2]
                   && m_ema25Buffer[1] < m_ema50Buffer[1])
                {
                    sl = m_zigZagTopBuffer[GetFirstPoint(m_zigZagTopBuffer)] 
                         + PointsToPriceShift(m_symbolCurrency, InpEma25Ema50AoSLBuffer);
                    
                    double entry = m_infoCurrency.bid();
                    tp = entry - MathAbs(sl - entry) * InpEma25Ema50AoTpRatio;
                    
                    slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                    if(slPoints > InpEma25Ema50AoSLMaxPoint || slPoints < InpEma25Ema50AoSLMinPoint)
                        return;
                    tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                    comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    m_trader.Sell(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                }
                
                // BUY
                if(m_aoBuffer[1] > m_aoBuffer[2] && m_aoBuffer[2] > 0
                   && m_ema25Buffer[2] < m_ema50Buffer[2]
                   && m_ema25Buffer[1] > m_ema50Buffer[1])
                {
                    sl = m_zigZagBottomBuffer[GetFirstPoint(m_zigZagBottomBuffer)]
                         - PointsToPriceShift(m_symbolCurrency, InpEma25Ema50AoSLBuffer);
                    
                    double entry = m_infoCurrency.ask();
                    tp = entry + MathAbs(sl - entry) * InpEma25Ema50AoTpRatio;
                    slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                    if(slPoints > InpEma25Ema50AoSLMaxPoint || slPoints < InpEma25Ema50AoSLMinPoint)
                        return;
                    tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                    comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    m_trader.Buy(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                }
            }
            
        }
};