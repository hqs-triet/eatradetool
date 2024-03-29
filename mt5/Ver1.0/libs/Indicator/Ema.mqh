
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IIndicator.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
//input int InpEma_Period = 200; // |- Giai đoạn tính toán EMA
//input ENUM_APPLIED_PRICE InpEma_AppliedPrice = PRICE_CLOSE; // |- Giai đoạn tính toán EMA
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CEma: public IIndicator
{
    private:
        double m_emaBuffer[];
        int m_emaHandler;
        int m_period;
        ENUM_APPLIED_PRICE m_appliedPrice;
    public:
        
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, int period, ENUM_APPLIED_PRICE appliedPrice)
        {
            IIndicator::Init(symbol, tf, infoCurrency);
            
            m_period = period;
            m_appliedPrice = appliedPrice;
            ArraySetAsSeries(m_emaBuffer, true);
            m_emaHandler = iMA(m_symbolCurrency, m_tf, m_period, 0, MODE_EMA, m_appliedPrice);
            if(m_emaHandler == INVALID_HANDLE)
            {
                Print("Không khởi tạo được EMA " + m_period);
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
            CopyBuffer(m_emaHandler, 0, 0, bars, m_emaBuffer);
        }
        double Value(int idx)
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_emaBuffer))
                    return m_emaBuffer[idx];
            }
            return 0;
        }
};