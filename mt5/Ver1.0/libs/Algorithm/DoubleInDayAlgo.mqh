
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#include  "..\PriceAction.mqh"
#resource "\\Indicators\\Examples\\ZigZagColor.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

input double InpDoubleInDayLotFix = 0.01;   // Lot cố định
input double InpDoubleInDayLotPercent = 0;  // Hoặc dùng theo % (nếu > 0 thì ưu tiên)
input int   InpDoubleInDayMinSL = 250;                  // SL thấp nhất (tính theo point)
input double InpDoubleInDaySLVsAtr = 1;     // Thiết lập SL so với ATR
input int   InpDoubleInDayFixSL = 0;  // Hoặc ưu tiên dùng SL cố định (tính theo point)
input group "Thiết lập chiến thuật ""double in a day"""
input bool   InpUseDoubleInDay = false;                 // Sử dụng chiến thuật topup
input int    InpDoubleInDayTopupOrders = 3;             // Số lệnh topup
input string InpDoubleInDayLotsRatioChain = "1;2;5";    // Tỉ lệ lot của top cách bằng dấu ";"
input string InpDoubleInDayDistanceRatioChain = "2;4;5"; // Tỉ lệ khoảng cách so với init
input double InpDoubleInDayTpRatioVsSLFromLastTopup = 2;  // Tỉ lệ TP so với SL tính từ order cuối
input int    InpDoubleInDayPeriodTrend = 200;
input int    InpDoubleInDayMaxPeriodCheckTopBottom = 300;
#include  "..\DoubleInDay.mqh"
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình EMA tỏa ra, thừa kế IAlgorithm
// ===================================================================
class CDoubleInDayAlgo: public IAlgorithm
{
    private:
        double m_lot;
        double m_zigzagTopBuffer[], m_zigzagBottomBuffer[], m_emaBuffer[], m_atrBuffer[], m_rsiBuffer[], 
               m_envelopsUpperBuffer[], m_envelopsLowerBuffer[];
        int m_zigzagHandler, m_emaHandler, m_atrHandler, m_rsiHandler, m_envelopsHandler;
        CDoubleInDay *m_doubleInDay;
        datetime m_lastTimeOps;
        bool m_autoTrade;
        
    public:
        void Vol(double vol)
        {
            m_lot = vol;
        }
        void AutoTrade(bool auto)
        {
            m_autoTrade = auto;
        }
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       string prefixComment, int magicNumber)
        {
            IAlgorithm::Init(symbol, tf, trader, infoCurrency, prefixComment, magicNumber);
            
            InitSeries(m_zigzagTopBuffer);
            InitSeries(m_zigzagBottomBuffer);
            m_zigzagHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\Examples\\ZigZagColor",
                                    8, 5, 3
                                   );
            m_lot = InpDoubleInDayLotFix;
            
            if(InpUseDoubleInDay)
            {
                m_doubleInDay = new CDoubleInDay();
                m_doubleInDay.Init(m_symbolCurrency, m_tf, m_trader, m_infoCurrency, m_magicNumber);
                m_doubleInDay.LotRatioChain(InpDoubleInDayLotsRatioChain);
                m_doubleInDay.SetAppendComment(m_prefixComment);
                m_doubleInDay.Topup(InpDoubleInDayTopupOrders);
                m_doubleInDay.DistancesRatio(InpDoubleInDayDistanceRatioChain);
                m_doubleInDay.TpRatioFromLastTopup(InpDoubleInDayTpRatioVsSLFromLastTopup);
            }
            
            InitSeries(m_emaBuffer);
            m_emaHandler = iMA(m_symbolCurrency, m_tf, InpDoubleInDayPeriodTrend, 0, MODE_EMA, PRICE_CLOSE);
            
            //iRSI(m_symbolCurrency, m_tf, 14, PRICE_CLOSE);
            //iMACD(m_symbolCurrency, m_tf, 12, 26, 9, PRICE_CLOSE);
            
            InitSeries(m_atrBuffer);
            m_atrHandler = iATR(m_symbolCurrency, m_tf, 14);
            
            InitSeries(m_rsiBuffer);
            m_rsiHandler = iRSI(m_symbolCurrency, m_tf, 8, PRICE_CLOSE);
            
            InitSeries(m_envelopsUpperBuffer);
            InitSeries(m_envelopsLowerBuffer);
            m_envelopsHandler = iEnvelopes(m_symbolCurrency, m_tf, 8, 0, MODE_SMA, PRICE_MEDIAN, 0.22);
            
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            if(InpUseDoubleInDay)
                m_doubleInDay.Process(limit);

            m_infoCurrency.refresh();
            
            if(!m_autoTrade)
                return;
                
            if(limit <= 0)
                return;
            
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_zigzagHandler, 0, 0, bars, m_zigzagTopBuffer);
            CopyBuffer(m_zigzagHandler, 1, 0, bars, m_zigzagBottomBuffer);
            
            CopyBuffer(m_emaHandler, 0, 0, bars, m_emaBuffer);
            CopyBuffer(m_atrHandler, 0, 0, bars, m_atrBuffer);
            
            CopyBuffer(m_rsiHandler, 0, 0, bars, m_rsiBuffer);
            CopyBuffer(m_envelopsHandler, 0, 0, bars, m_envelopsUpperBuffer);
            CopyBuffer(m_envelopsHandler, 1, 0, bars, m_envelopsLowerBuffer);
            int openPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
            //int pendingOrder = GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment + ";01")
            //                   + GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment + ";01");
            
            if(openPos == 0)
            {
                
                ProcessBuy(limit);
                ProcessSell(limit);
            }
        }
        bool CanSell()
        {
            if(m_zigzagTopBuffer[1] > 0)
            {
                if(m_rsiBuffer[1] > 80 &&
                   m_zigzagTopBuffer[1] > m_envelopsUpperBuffer[1]
                   //&& m_infoCurrency.low(1) > m_envelopsUpperBuffer[1] 
                   //&& m_zigzagTopBuffer[1] < m_emaBuffer[1]
                   //&& (IsReverseHammerBar(1, m_infoCurrency) || IsEngulfing(1, m_infoCurrency))
                   )
                   return true;
                //int prevTopPoint = GetFirstPoint(m_zigzagTopBuffer, 3);
                //int prev2TopPoint = GetFirstPoint(m_zigzagTopBuffer, prevTopPoint + 1);
                //if(m_zigzagTopBuffer[2] > m_zigzagTopBuffer[prevTopPoint] &&
                //   //m_rsiBuffer[2] < m_rsiBuffer[prevTopPoint] &&
                //   m_rsiBuffer[2] > 80 &&
                //   (m_rsiBuffer[prevTopPoint] > 80
                //    || m_rsiBuffer[prevTopPoint + 1] > 80
                //    ||m_rsiBuffer[prevTopPoint - 1] > 80)
                //   && m_zigzagTopBuffer[prevTopPoint] > m_zigzagTopBuffer[prev2TopPoint]
                //   //IsReverseHammerBar(1, m_infoCurrency)
                //   )
                //   return true;
            
            }
            
            //if(m_zigzagTopBuffer[1] > 0)
            //{
            //    int count = CountPoints(m_zigzagTopBuffer, m_zigzagTopBuffer[1], 2, 
            //                            InpDoubleInDayMaxPeriodCheckTopBottom);
            //    if(count > 2)// && m_zigzagTopBuffer[1] < m_emaBuffer[1])
            //        return true;
            //}
            
            
            return false;
            //if(m_zigzagTopBuffer[1] > 0)
            //    if(CandleTailUpPercent(1, m_infoCurrency) >= 30 &&
            //       m_infoCurrency.high(1) > m_emaBuffer[1] &&
            //       m_infoCurrency.close(1) < m_emaBuffer[1] &&
            //       m_infoCurrency.open(1) < m_emaBuffer[1])
            //    {
            //        return true;
            //    }
            //return false;
            
            // ================================================
            //if(IsReverseHammerBar(1, m_infoCurrency) || 
            //   IsPinBarBig(1, m_infoCurrency)  ||
            //   IsPinBarSmall(1, m_infoCurrency))
            //   return true;
            if(m_zigzagTopBuffer[2] > 0)
            {
                int prevBottomPoint = GetFirstPoint(m_zigzagBottomBuffer, 3);
                prevBottomPoint = GetFirstPoint(m_zigzagBottomBuffer, prevBottomPoint + 1);
                int prevTopPoint = GetFirstPoint(m_zigzagTopBuffer, 3);
                int prev2TopPoint = GetFirstPoint(m_zigzagTopBuffer, prevTopPoint + 1);
                int diffPoints = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(m_zigzagTopBuffer[2] - m_zigzagTopBuffer[prevTopPoint]));
                int diffPoints2 = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(m_zigzagTopBuffer[2] - m_zigzagTopBuffer[prev2TopPoint]));
                int diffPoints3 = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(m_zigzagTopBuffer[2] - m_zigzagBottomBuffer[prevBottomPoint]));
                                     
                if((diffPoints <= InpDoubleInDayMinSL 
                    || (diffPoints2 <= InpDoubleInDayMinSL
                        && m_zigzagTopBuffer[prev2TopPoint] > m_zigzagTopBuffer[prevTopPoint])
                    || diffPoints3 <= InpDoubleInDayMinSL
                    ) &&
                   m_zigzagTopBuffer[prevTopPoint] < m_emaBuffer[1] &&
                   CandleTailUpPercent(2, m_infoCurrency) >= 20 &&
                   //&& CandleTailUpPercent(1, m_infoCurrency) >= 15
                   IsCandleDown(1, m_infoCurrency)
                   && m_zigzagTopBuffer[2] < m_emaBuffer[1]
                   )
                    return true;
            }
            return false;
        }
        
        bool CanBuy()
        {
            if(m_zigzagBottomBuffer[1] > 0)
            {
                if(m_rsiBuffer[1] < 20 &&
                   m_zigzagBottomBuffer[1] < m_envelopsLowerBuffer[1]
                   //&& m_infoCurrency.high(1) < m_envelopsLowerBuffer[1] 
                   //&& m_zigzagBottomBuffer[1] > m_emaBuffer[1]
                   //&& (IsHammerBar(1, m_infoCurrency) || IsEngulfing(1, m_infoCurrency))
                   )
                   return true;
                   
                //int prevBottomPoint = GetFirstPoint(m_zigzagBottomBuffer, 3);
                //int prev2BottomPoint = GetFirstPoint(m_zigzagBottomBuffer, prevBottomPoint + 1);
                //if(m_zigzagBottomBuffer[2] < m_zigzagBottomBuffer[prevBottomPoint] &&
                //   //m_rsiBuffer[2] > m_zigzagBottomBuffer[prevBottomPoint] &&
                //   m_rsiBuffer[2] < 20 &&
                //   (m_rsiBuffer[prevBottomPoint] < 20
                //    || m_rsiBuffer[prevBottomPoint + 1] < 20
                //    || m_rsiBuffer[prevBottomPoint] - 1 < 20)
                //   && m_zigzagBottomBuffer[prevBottomPoint] < m_zigzagBottomBuffer[prev2BottomPoint]
                //   //IsHammerBar(1, m_infoCurrency)
                //   )
                //   return true;
            
            }
            
            //if(m_zigzagBottomBuffer[1] > 0)
            //{
            //    int count = CountPoints(m_zigzagBottomBuffer, m_zigzagBottomBuffer[1], 2, 
            //                            InpDoubleInDayMaxPeriodCheckTopBottom);
            //    if(count > 2)// && m_zigzagBottomBuffer[1] > m_emaBuffer[1])
            //        return true;
            //}
            
            
            
            return false;
            
            //if(m_zigzagBottomBuffer[1] > 0)
            //    if(CandleTailDownPercent(1, m_infoCurrency) >= 30 &&
            //       m_infoCurrency.low(1) < m_emaBuffer[1] &&
            //       m_infoCurrency.close(1) > m_emaBuffer[1] &&
            //       m_infoCurrency.open(1) > m_emaBuffer[1])
            //    {
            //        return true;
            //    }
            //return false;
//            int prevBottomIdx = GetFirstPoint(m_zigzagBottomBuffer, 2);
//            int prevTopIdx = GetFirstPoint(m_zigzagTopBuffer, 2);
//            if(prevTopIdx < prevBottomIdx)
//            {
//                double height = MathAbs(m_zigzagTopBuffer[prevTopIdx] - m_zigzagBottomBuffer[prevBottomIdx]);
//                double heightPoints = PriceShiftToPoints(m_symbolCurrency, height);
//                if((heightPoints > InpDoubleInDayMinSL * 3)
//                {
//                    buyLimit = true;
//                }
//            }
            //return false;
            // ========================================================
            //if(IsHammerBar(1, m_infoCurrency) || 
            //   IsPinBarBig(1, m_infoCurrency)  ||
            //   IsPinBarSmall(1, m_infoCurrency))
            //   return true;
            if(m_zigzagBottomBuffer[2] > 0)
            {
                int prevTopPoint = GetFirstPoint(m_zigzagTopBuffer, 3);
                prevTopPoint = GetFirstPoint(m_zigzagTopBuffer, prevTopPoint + 1);
                int prevBottomPoint = GetFirstPoint(m_zigzagBottomBuffer, 3);
                int prev2BottomPoint = GetFirstPoint(m_zigzagBottomBuffer, prevBottomPoint + 1);
                
                
                int diffPoints = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(m_zigzagBottomBuffer[2] - m_zigzagBottomBuffer[prevBottomPoint]));
                                     
                int diffPoints2 = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(m_zigzagBottomBuffer[2] - m_zigzagBottomBuffer[prev2BottomPoint]));
                int diffPoints3 = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(m_zigzagBottomBuffer[2] - m_zigzagTopBuffer[prevTopPoint]));
                if((diffPoints <= InpDoubleInDayMinSL 
                    || (diffPoints2 <= InpDoubleInDayMinSL 
                        && m_zigzagBottomBuffer[prev2BottomPoint] < m_zigzagBottomBuffer[prevBottomPoint])
                    || diffPoints3 <= InpDoubleInDayMinSL
                    ) &&
                   m_zigzagBottomBuffer[prevBottomPoint] > m_emaBuffer[1] &&
                   CandleTailDownPercent(2, m_infoCurrency) >= 20 &&
                    //&& CandleTailDownPercent(1, m_infoCurrency) >= 15
                    IsCandleUp(1, m_infoCurrency)
                   && m_zigzagBottomBuffer[2] > m_emaBuffer[1]
                   )
                    return true;
            }
            return false;
        }
        
        void ProcessBuy(int limit)
        {
            if(CanBuy())
            {
                double entry = m_infoCurrency.ask();
                //double sl = GetMinPriceRange(m_infoCurrency, 1, 3, true);
                double sl = entry - m_atrBuffer[1] * InpDoubleInDaySLVsAtr;
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                if(slPoints < InpDoubleInDayMinSL)
                    slPoints = InpDoubleInDayMinSL;
                if(InpDoubleInDayFixSL > 0)
                    slPoints = InpDoubleInDayFixSL;
                sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
                
                string comment = m_prefixComment + ";01;" + (string)slPoints;
                if(InpDoubleInDayLotPercent > 0)
                    m_lot = (double)DoubleToString(PointsToLots(m_symbolCurrency, InpDoubleInDayLotPercent, slPoints), 2);
                ResetLastError();
                if(!m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, 0, comment))
                {
                    int code = GetLastError();
                    Print("Error code: " + (string)code);
                }
            }
        }
        
        
        void ProcessSell(int limit)
        {
            if(CanSell())
            {
                double entry = m_infoCurrency.bid();
                //double sl = GetMaxPriceRange(m_infoCurrency, 1, 3, true);
                double sl = entry + m_atrBuffer[1] * InpDoubleInDaySLVsAtr;
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                if(slPoints < InpDoubleInDayMinSL)
                    slPoints = InpDoubleInDayMinSL;
                if(InpDoubleInDayFixSL > 0)
                    slPoints = InpDoubleInDayFixSL;
                sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
                string comment = m_prefixComment + ";01;" + (string)slPoints;
                if(InpDoubleInDayLotPercent > 0)
                    m_lot = (double)DoubleToString(PointsToLots(m_symbolCurrency, InpDoubleInDayLotPercent, slPoints), 2);
                
                ResetLastError();
                if(!m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, 0, comment))
                {
                    int code = GetLastError();
                    Print("Error code: " + (string)code);
                }
            }
        }
        
        
        
        
        
        
        
        
        
        
        
        
        
        int CountPoints(double &zigzagBuffer[], double targetPrice, int fromIdx, int zone, int maxPeriod = 300)
        {
            int count = 0;
            for(int idx = fromIdx; idx <= fromIdx + maxPeriod - 1; idx++)
            {
                int diffPoints = PriceShiftToPoints(m_symbolCurrency, 
                                     MathAbs(zigzagBuffer[idx] - targetPrice));
                if(diffPoints <= zone)
                    count++;
            }
            return count;
        }
        bool IsLastTimeOpsDiffNow()
        {
            long totalSeconds = TimeCurrent() - m_lastTimeOps;
            
            if((m_tf == PERIOD_D1 && totalSeconds >= PeriodSeconds(PERIOD_D1)) ||
               (m_tf == PERIOD_H12 && totalSeconds >= PeriodSeconds(PERIOD_H12)) ||
               (m_tf == PERIOD_H4 && totalSeconds >= PeriodSeconds(PERIOD_H4)) ||
               (m_tf == PERIOD_H2 && totalSeconds >= PeriodSeconds(PERIOD_H2)) ||
               (m_tf == PERIOD_H1 && totalSeconds >= PeriodSeconds(PERIOD_H1)) ||
               (m_tf == PERIOD_M30 && totalSeconds >= PeriodSeconds(PERIOD_M30)) ||
               (m_tf == PERIOD_M15 && totalSeconds >= PeriodSeconds(PERIOD_M15)) ||
               (m_tf == PERIOD_M5 && totalSeconds >= PeriodSeconds(PERIOD_M5)) ||
               (m_tf == PERIOD_M1 && totalSeconds >= PeriodSeconds(PERIOD_M1))
              )
                return true;
            return false;
        }
};