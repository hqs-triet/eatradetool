
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "ICondition.mqh"
#resource "\\Indicators\\Examples\ZigZagColor.ex5"
#include <ChartObjects\ChartObjectsLines.mqh>

// ===================================================================
enum ENUM_RESSUP
{
    ENUM_RESSUP_RESISTANCE = 1,
    ENUM_RESSUP_SUPPORT = 2
};
// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý phát hiện kháng cự/hỗ trợ, thừa kế ICondition
// ===================================================================
class CResSup: public ICondition
{
    private:
        double m_zigZagTopBuffer[], m_zigZagBottomBuffer[];
        int m_zigZagHandler;
        int m_period, m_depth, m_minPeriod, m_zone;
        bool m_suggestSell, m_suggestBuy;
    public:
        bool SuggestBuy()
        {
            return m_suggestBuy;
        }
        bool SuggestSell()
        {
            return m_suggestSell;
        }
        // =======================================================
        // Khởi tạo các thông số
        // =======================================================
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, int period, int depth, int minPeriod, int zone)
        {
            ICondition::Init(symbol, tf, infoCurrency);
            
            m_period = period;
            m_depth = depth;
            m_minPeriod= minPeriod;
            m_zone = zone;
            
            ArraySetAsSeries(m_zigZagTopBuffer, true);
            ArraySetAsSeries(m_zigZagBottomBuffer, true);
            m_zigZagHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\Examples\\ZigZagColor",
                                         m_depth, 5, 3
                                        );
            if(m_zigZagHandler == INVALID_HANDLE)
            {
                Print("Không khởi tạo được Zigzag");
                return INIT_FAILED;
            }
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_zigZagHandler, 0, 0, bars, m_zigZagTopBuffer);
            CopyBuffer(m_zigZagHandler, 1, 0, bars, m_zigZagBottomBuffer);
        }
        
        // =======================================================
        // Phát hiện kháng cự/hỗ trợ
        // flag: giá trị chỉ định của ENUM_RES_SUP
        // =======================================================
        bool IsMatched(int limit, int flag)
        {
            m_suggestSell = m_suggestBuy = false;
            double zonePriceShift= PointsToPriceShift(m_symbolCurrency, m_zone);
            int idxFirstRes = GetFirstPoint(m_zigZagTopBuffer, m_minPeriod);
            int idxFirstSup = GetFirstPoint(m_zigZagBottomBuffer, m_minPeriod);
            double resPriceTopCheck = m_zigZagTopBuffer[idxFirstRes] + zonePriceShift;
            double resPriceBottomCheck = m_zigZagTopBuffer[idxFirstRes] - zonePriceShift;
            double supPriceTopCheck = m_zigZagBottomBuffer[idxFirstSup] + zonePriceShift;
            double supPriceBottomCheck = m_zigZagBottomBuffer[idxFirstSup] - zonePriceShift;
            double currentPrice = m_infoCurrency.close(0);
            
            if(flag == (int)ENUM_RESSUP_RESISTANCE)
            {
                if(currentPrice < resPriceTopCheck && currentPrice > resPriceBottomCheck)
                {
                    double percentBelow = GetPercentCandlesBelowPrice(m_infoCurrency, idxFirstRes, currentPrice);
                    double percentAbove = GetPercentCandlesAbovePrice(m_infoCurrency, idxFirstRes, currentPrice);
                    if(percentBelow >= 80)
                        m_suggestSell = true;
                    else if(percentAbove >= 20)
                        m_suggestBuy = true;
                    return true;
                }
            }
            if(flag == (int)ENUM_RESSUP_SUPPORT)
            {
                if(currentPrice < supPriceTopCheck && currentPrice > supPriceBottomCheck)
                {
                    double percentAbove = GetPercentCandlesAbovePrice(m_infoCurrency, idxFirstSup, currentPrice);
                    double percentBelow = GetPercentCandlesBelowPrice(m_infoCurrency, idxFirstSup, currentPrice);
                    if(percentAbove >= 80)
                        m_suggestBuy = true;
                    else if(percentBelow >= 20)
                        m_suggestSell = true;
                    return true;
                }
            }
            return false;
        }
};