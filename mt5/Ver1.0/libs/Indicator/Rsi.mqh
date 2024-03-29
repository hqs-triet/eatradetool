
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IIndicator.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CRsi: public IIndicator
{
    private:
        double m_rsiBuffer[];
        int m_rsiHandler;
        int m_period;
        ENUM_APPLIED_PRICE m_appliedPrice;
    public:
        
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, int period, ENUM_APPLIED_PRICE appliedPrice)
        {
            IIndicator::Init(symbol, tf, infoCurrency);
            
            m_period = period;
            m_appliedPrice = appliedPrice;
            ArraySetAsSeries(m_rsiBuffer, true);
            m_rsiHandler = iRSI(m_symbolCurrency, m_tf, m_period, m_appliedPrice);
            if(m_rsiHandler == INVALID_HANDLE)
            {
                Print("Không khởi tạo được RSI " + m_period);
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
            CopyBuffer(m_rsiHandler, 0, 0, bars, m_rsiBuffer);
        }
        double Value(int idx)
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_rsiBuffer))
                    return m_rsiBuffer[idx];
            }
            return 0;
        }
};