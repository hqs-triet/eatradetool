
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#include  "../Indicator/Ichimoku.mqh"
#include  "../Indicator/ZigzagColor.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpClimbUpIchimokuLotFix = 0.01;   // Lot cố định
input double InpClimbUpIchimokuLotPercent = 0;  // Hoặc theo % tài khoản (nếu > 0 thì ưu tiên)
input double InpClimbUpIchimokuRR = 3.0;        // Tỉ lệ TP so với SL (RR)
input group "Thiết lập khi đủ điều kiện vào lệnh"
input bool InpClimbUpIchimokuMakeOrder = true;  // Đặt lệnh
input bool InpClimbUpIchimokuSendNotification = true;  // Gởi thông báo tới điện thoại
input bool InpClimbUpIchimokuAlert = true;  // Hiển thị thông báo lên màn hình

input group "Thông số Ichimoku"
input int InpClimbUpIchimokuTenkan = 9; // Tenkan
input int InpClimbUpIchimokuKijun = 26; // Kijun
input int InpClimbUpIchimokuSenkouSpanB = 52;   // Senkou Span B
input group "Thông số Zigzag (lấy giá trị đỉnh đáy)"
input int InpClimbUpIchimokuZigzagDepth = 12;   // Depth
input int InpClimbUpIchimokuZigzagDeviation = 5;    // Deviation
input int InpClimbUpIchimokuZigzagBackstep = 3; // Back step

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo thuật toán ichimoku, thừa kế IAlgorithm
// ===================================================================
class CClimbUpIchimokuAlgoAlgo: public IAlgorithm
{
    private:
        double m_lot;
        CIchimoku m_ichimokuH1, m_ichimokuM15;
        CZigzagColor m_zigzagM15;
        AllSeriesInfo m_infoCurrencyH1, m_infoCurrencyM15;
        bool m_autoTrade;
        bool m_sentNotiBuy, m_sentNotiSell;
        bool m_lastIsSell, m_lastIsBuy;
    public:
        void Vol(double vol)
        {
            m_lot = vol;
        }
        void AutoTrade(bool autoTrade)
        {
            m_autoTrade = autoTrade;
        }
        int Init(string symbol, ENUM_TIMEFRAMES mainTf, 
                       CTrade &mainTrader, AllSeriesInfo &mainInfoCurrency,
                       string prefixComment, ulong magicNumber, 
                       ENUM_TIMEFRAMES tfMajor, ENUM_TIMEFRAMES tfSub)
        {
            IAlgorithm::Init(symbol, mainTf, mainTrader, mainInfoCurrency, prefixComment, magicNumber);
            
            m_infoCurrencyH1.init(m_symbolCurrency, tfMajor);
            m_infoCurrencyM15.init(m_symbolCurrency, tfSub);
            
            m_ichimokuH1.Init(m_symbolCurrency, tfMajor, m_infoCurrencyH1, 
                              InpClimbUpIchimokuTenkan, InpClimbUpIchimokuKijun, InpClimbUpIchimokuSenkouSpanB);
            m_ichimokuM15.Init(m_symbolCurrency, tfSub, m_infoCurrencyM15, 
                              InpClimbUpIchimokuTenkan, InpClimbUpIchimokuKijun, InpClimbUpIchimokuSenkouSpanB);
            m_zigzagM15.Init(m_symbolCurrency, tfSub, m_infoCurrencyM15,
                              InpClimbUpIchimokuZigzagDepth, InpClimbUpIchimokuZigzagDeviation, InpClimbUpIchimokuZigzagBackstep);
            
            m_lot = InpClimbUpIchimokuLotFix;
            m_autoTrade = false;
            m_sentNotiBuy = false;
            m_sentNotiSell = false;
            m_lastIsSell = false;
            m_lastIsBuy = false;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            if(!m_autoTrade)
            {
                return;
            }
            
            if(limit <= 0)
                return;
            m_infoCurrency.refresh();
            m_ichimokuH1.Refresh(limit);
            m_ichimokuM15.Refresh(limit);
            m_zigzagM15.Refresh(limit);
            
            int totalPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
            if(totalPos == 0)
            {
                ProcessBuy(limit);
                ProcessSell(limit);
            }
            
        }
        bool CanSell()
        {
            bool canSell  = false;
            // Điều kiện của H1
            canSell = (m_ichimokuH1.Tenkan(1) < m_ichimokuH1.SenkouSpanA(1)
                      && m_ichimokuH1.Tenkan(1) < m_ichimokuH1.SenkouSpanB(1)
                      && m_ichimokuH1.Kijun(1) < m_ichimokuH1.SenkouSpanA(1)
                      && m_ichimokuH1.Kijun(1) < m_ichimokuH1.SenkouSpanB(1));
                      
            canSell &= m_infoCurrencyH1.close(1) < m_ichimokuH1.SenkouSpanA(1)
                       && m_infoCurrencyH1.close(1) < m_ichimokuH1.SenkouSpanB(1);
            // Điều kiện của M15
            if(canSell)
            {
                //Print("Matching SELL H1 condition first time!");
            }
            canSell &= m_ichimokuM15.SenkouSpanA(1) <= m_ichimokuM15.SenkouSpanB(1)
                       && m_ichimokuM15.SenkouSpanA(2) > m_ichimokuM15.SenkouSpanB(2);
            canSell &= m_infoCurrencyM15.close(1) < m_ichimokuM15.SenkouSpanA(1)
                       && m_infoCurrencyM15.close(1) < m_ichimokuM15.SenkouSpanB(1);
            //if(canSell)
            //    Print("Matching SELL condition first time!");
            return canSell;
        }
        
        bool CanBuy()
        {
            
            bool canBuy  = false;
            // Điều kiện của H1
            canBuy = (m_ichimokuH1.Tenkan(1) > m_ichimokuH1.SenkouSpanA(1)
                      && m_ichimokuH1.Tenkan(1) > m_ichimokuH1.SenkouSpanB(1)
                      && m_ichimokuH1.Kijun(1) > m_ichimokuH1.SenkouSpanA(1)
                      && m_ichimokuH1.Kijun(1) > m_ichimokuH1.SenkouSpanB(1));
                      
            canBuy &= m_infoCurrencyH1.close(1) > m_ichimokuH1.SenkouSpanA(1)
                       && m_infoCurrencyH1.close(1) > m_ichimokuH1.SenkouSpanB(1);
            // Điều kiện của M15
            if(canBuy)
            {
                //Print("Matching BUY H1 condition first time!");
            }
            canBuy &= m_ichimokuM15.SenkouSpanA(1) >= m_ichimokuM15.SenkouSpanB(1)
                      && m_ichimokuM15.SenkouSpanA(2) < m_ichimokuM15.SenkouSpanB(2);
            canBuy &= m_infoCurrencyM15.close(1) > m_ichimokuM15.SenkouSpanA(1)
                      && m_infoCurrencyM15.close(1) > m_ichimokuM15.SenkouSpanB(1);
            //if(canBuy)
            //    Print("Matching BUY condition first time!");
            return canBuy;
        }
        
        void ProcessBuy(int limit)
        {
            if(CanBuy() && !m_lastIsBuy)
            {
                // ====================================================
                // Gởi thông báo
                m_sentNotiSell = false;
                if(InpClimbUpIchimokuSendNotification
                   || InpClimbUpIchimokuAlert)
                {
                    string msg = "==== Thỏa điều kiện BUY, hãy xem xét vào lệnh!";
                    if(!m_sentNotiBuy)
                    {
                        if(InpClimbUpIchimokuSendNotification)
                            SendNotification(msg);
                        if(InpClimbUpIchimokuAlert)
                            Alert(msg);
                        m_sentNotiBuy = true;
                    }
                }
                if(!InpClimbUpIchimokuMakeOrder)
                    return;
                
                // ====================================================
                
                double entry = m_infoCurrency.ask();
                double sl, tp;
                int slPoints, tpPoints;
                
                sl = m_zigzagM15.FirstBottom(2);
                slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                
                // =================================================================================
                // Lệnh thứ 1 với RR = 1:3
                tp = entry + MathAbs((entry - sl) * InpClimbUpIchimokuRR);
                tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));

                string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                if(InpClimbUpIchimokuLotPercent > 0)
                    m_lot = (double)DoubleToString(PointsToLots(m_symbolCurrency, 
                                                   InpClimbUpIchimokuLotPercent, slPoints), 2);
                if(m_lot == 0)
                {
                    Print("Lỗi khi đặt lệnh với lot không hợp lệ: " + (string)m_lot);
                }
                ResetLastError();
                if(!m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment))
                {
                    int code = GetLastError();
                    Print("Lỗi khi đặt lệnh RR=1:3 với mã lỗi: " + (string)code);
                }
                m_lastIsBuy = true;
                m_lastIsSell = false;
                
                // =================================================================================
                // Lệnh thứ 2 với RR = 1:1
                tp = entry + MathAbs(entry - sl);
                tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));

                comment = m_prefixComment + ";02;" + (string)slPoints + ";" + (string)tpPoints;
                if(InpClimbUpIchimokuLotPercent > 0)
                    m_lot = (double)DoubleToString(PointsToLots(m_symbolCurrency, 
                                                   InpClimbUpIchimokuLotPercent, slPoints), 2);
                if(m_lot == 0)
                {
                    Print("Lỗi khi đặt lệnh với lot không hợp lệ: " + (string)m_lot);
                }
                
                ResetLastError();
                if(!m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment))
                {
                    int code = GetLastError();
                    Print("Lỗi khi đặt lệnh RR=1:1 với mã lỗi: " + (string)code);
                }
                m_lastIsBuy = true;
                m_lastIsSell = false;
            }
        }
        
        
        void ProcessSell(int limit)
        {
            if(CanSell() && !m_lastIsSell)
            {
                // ====================================================
                // Gởi thông báo
                m_sentNotiBuy = false;
                if(InpClimbUpIchimokuSendNotification
                   || InpClimbUpIchimokuAlert)
                {
                    string msg = "==== Thỏa điều kiện SELL, hãy xem xét vào lệnh!";
                    if(!m_sentNotiSell)
                    {
                        if(InpClimbUpIchimokuSendNotification)
                            SendNotification(msg);
                        if(InpClimbUpIchimokuAlert)
                            Alert(msg);
                        m_sentNotiSell = true;
                    }
                }
                if(!InpClimbUpIchimokuMakeOrder)
                    return;
                
                // ====================================================
                
                double entry = m_infoCurrency.bid();
                double sl, tp;
                int slPoints, tpPoints;
                
                sl = m_zigzagM15.FirstTop(2);
                slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                
                // =================================================================================
                // Lệnh thứ 1 với RR = 1:3
                tp = entry - MathAbs((entry - sl) * InpClimbUpIchimokuRR);
                tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));

                string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                if(InpClimbUpIchimokuLotPercent > 0)
                    m_lot = (double)DoubleToString(PointsToLots(m_symbolCurrency, 
                                                   InpClimbUpIchimokuLotPercent, slPoints), 2);
                if(m_lot == 0)
                {
                    Print("Lỗi khi đặt lệnh với lot không hợp lệ: " + (string)m_lot);
                }
                ResetLastError();
                if(!m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment))
                {
                    int code = GetLastError();
                    Print("Lỗi khi đặt lệnh RR=1:3 với mã lỗi: " + (string)code);
                }
                m_lastIsBuy = false;
                m_lastIsSell = true;
                
                // =================================================================================
                // Lệnh thứ 2 với RR = 1:1
                tp = entry - MathAbs(entry - sl);
                tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));

                comment = m_prefixComment + ";02;" + (string)slPoints + ";" + (string)tpPoints;
                if(InpClimbUpIchimokuLotPercent > 0)
                    m_lot = (double)DoubleToString(PointsToLots(m_symbolCurrency, 
                                                   InpClimbUpIchimokuLotPercent, slPoints), 2);
                if(m_lot == 0)
                {
                    Print("Lỗi khi đặt lệnh với lot không hợp lệ: " + (string)m_lot);
                }
                
                ResetLastError();
                if(!m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment))
                {
                    int code = GetLastError();
                    Print("Lỗi khi đặt lệnh RR=1:1 với mã lỗi: " + (string)code);
                }
                m_lastIsBuy = false;
                m_lastIsSell = true;
            }
        }
        
};