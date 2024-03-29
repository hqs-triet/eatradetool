
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

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình EMA tỏa ra, thừa kế IAlgorithm
// ===================================================================
class CGridTest: public IAlgorithm
{
    private:
        double m_lot;
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
            
            m_lot = 0.01;
            
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            if(limit <= 0)
                return;
            
        }
};