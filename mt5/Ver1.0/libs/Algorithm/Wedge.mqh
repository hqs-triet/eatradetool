
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#include  "..\..\libs\Condition\WedgePattern.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input group "Mô hình cái nêm - Thiết lập chung"
input int InpWedge_Period = 200;                     // Giai đoạn kiểm tra
input int InpWedge_Depth = 8;                       // Độ sâu kiểm tra đỉnh đáy (zigzag)
input int InpWedgeMaxCandlesFromCrossPoint = 50;    // Khoảng cách nến tối đa từ điểm giao cắt 2 đường xu hướng
input int InpWedgeMinPeriodOf2Points = 40;          // Khoảng cách nến tối thiểu của 2 đỉnh/đáy của đường xu hướng

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình cái nêm, thừa kế IAlgorithm
// ===================================================================
class CWedge: public IAlgorithm
{
    private:
        double m_lot;
        CWedgePattern m_wedgePattern;
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
            
            // Khởi tạo đối tượng: mô hình cái nêm
            if(m_wedgePattern.Init(m_symbolCurrency, m_tf, m_infoCurrency, 
                           InpWedge_Period, InpWedge_Depth, InpWedgeMaxCandlesFromCrossPoint, InpWedgeMinPeriodOf2Points) == INIT_FAILED)
                return false;

            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            // Xử lý điều kiện
            m_wedgePattern.Process(limit);
            
            // Phát hiện mô hình cái nêm
            if(m_wedgePattern.IsMatched(limit, 0))
            {
                Print("Phát hiện mô hình cái nêm!");
                if(m_wedgePattern.IsRiseWedge())
                    Print("Mô hình cái nêm tăng: xem xét SELL!");
                if(m_wedgePattern.IsFallWedge())
                    Print("Mô hình cái nêm giảm: xem xét BUY!");
            }
        }
};