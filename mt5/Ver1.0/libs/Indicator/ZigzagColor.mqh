
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IIndicator.mqh"
#resource "\\Indicators\\Examples\\ZigZagColor.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng chỉ báo cho Ichimoku, thừa kế IAlgorithm
// ===================================================================
class CZigzagColor: public IIndicator
{
    private:
        double m_zigzagTopBuffer[], m_zigzagBottomBuffer[];
        int m_zigzagHandler;
        int m_depth, m_deviation, m_backStep;
    public:
        
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, 
                 int depth = 8, int deviation = 5, int backStep = 3)
        {
            IIndicator::Init(symbol, tf, infoCurrency);
            
            m_depth = depth;
            m_deviation = deviation;
            m_backStep = backStep;
            
            InitSeries(m_zigzagTopBuffer);
            InitSeries(m_zigzagBottomBuffer);
            m_zigzagHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\Examples\\ZigZagColor",
                                    m_depth, m_deviation, m_backStep);
            if(m_zigzagHandler == INVALID_HANDLE)
            {
                Print("Không khởi tạo được ZigZag (" + 
                      (string)m_depth + "," + 
                      (string)m_deviation + "," + 
                      (string)m_backStep + ")");
                m_isInitialized = false;
                return INIT_FAILED;
            }
            m_isInitialized = true;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Refresh(int limit)
        {
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_zigzagHandler, 0, 0, bars, m_zigzagTopBuffer);
            CopyBuffer(m_zigzagHandler, 1, 0, bars, m_zigzagBottomBuffer);
        }
        // Not use this function
        double Value(int idx)
        {
            return 0;
        }
        double Top(int idx)
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_zigzagTopBuffer))
                    return m_zigzagTopBuffer[idx];
            }
            return 0;
        }
        double Bottom(int idx) 
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_zigzagBottomBuffer))
                    return m_zigzagBottomBuffer[idx];
            }
            return 0;
        }
        double FirstTop(int fromIdx = 1) 
        {
            int idx = GetFirstPoint(m_zigzagTopBuffer, fromIdx);
            if(idx < fromIdx)
                return 0;
            return m_zigzagTopBuffer[idx];
        }
        double FirstBottom(int fromIdx = 1) 
        {
            int idx = GetFirstPoint(m_zigzagBottomBuffer, fromIdx);
            if(idx < fromIdx)
                return 0;
            return m_zigzagBottomBuffer[idx];
        }
};