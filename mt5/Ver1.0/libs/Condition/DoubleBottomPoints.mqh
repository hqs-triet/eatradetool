
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "ICondition.mqh"
#resource "\\Indicators\\Examples\ZigZagColor.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CDoubleBottomPoints: public ICondition
{
    private:
        double m_zigZagTopBuffer[], m_zigZagBottomBuffer[];
        int m_zigZagHandler;
        int m_period, m_zone, m_depth;
        int m_minPeriod2BottomPoints;
    public:
        
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, int zone, int period, int depth, int minPeriod2BottomPoints)
        {
            ICondition::Init(symbol, tf, infoCurrency);
            
            m_zone = zone;
            m_period = period;
            m_depth = depth;
            m_minPeriod2BottomPoints = minPeriod2BottomPoints;
            
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
        // Phát hiện mô hình 2 đáy
        // =======================================================
        bool IsMatched(int limit, int flag)
        {
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer);
            if(idxFirstBottomPoint == 1)
                return false;
                
            int idxSecondBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, idxFirstBottomPoint + 1);
            
            if(idxSecondBottomPoint > m_period)
                return false;
            
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer, 2);
            if(idxFirstTopPoint < idxFirstBottomPoint)
                return false;
            
            if(idxSecondBottomPoint - idxFirstBottomPoint < m_minPeriod2BottomPoints)
                return false;
            
            double zone = PointsToPriceShift(m_symbolCurrency, m_zone);
            if(MathAbs(m_zigZagBottomBuffer[idxFirstBottomPoint] - m_zigZagBottomBuffer[idxSecondBottomPoint]) > zone)
                return false;
            
            double neckPrice = NecklinePrice();
            if(m_infoCurrency.close(1) <= neckPrice)
                return false;
                
            return true;
        }
        
        // =======================================================
        // Phát hiện có dấu hiệu mô hình 2 đáy
        // =======================================================
        bool HasSignalMatched(int limit, int flag)
        {
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer);
            if(idxFirstBottomPoint == 1)
                return false;
                
            int idxSecondBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, idxFirstBottomPoint + 1);
            
            if(idxSecondBottomPoint > m_period)
                return false;
            
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer, 2);
            if(idxFirstTopPoint < idxFirstBottomPoint)
                return false;
            
            if(idxSecondBottomPoint - idxFirstBottomPoint < m_minPeriod2BottomPoints)
                return false;
            
            double zone = PointsToPriceShift(m_symbolCurrency, m_zone);
            if(MathAbs(m_zigZagBottomBuffer[idxFirstBottomPoint] - m_zigZagBottomBuffer[idxSecondBottomPoint]) > zone)
                return false;
                
            return true;
        }
        
        // =======================================================
        // Giá neckline
        // =======================================================
        double NecklinePrice()
        {
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer);
            int idxSecondBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, idxFirstBottomPoint + 1);
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer, 2);
            if(idxFirstTopPoint > idxFirstBottomPoint 
               && idxFirstTopPoint < idxSecondBottomPoint)
                return m_zigZagTopBuffer[idxFirstTopPoint];
            return 0;
        }
        
        // =======================================================
        // Giá thấp nhất (đáy) của mô hình
        // =======================================================
        double BottomPointPrice()
        {
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer);
            int idxSecondBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, idxFirstBottomPoint + 1);
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer, 2);
            if(idxFirstTopPoint > idxFirstBottomPoint 
               && idxFirstTopPoint < idxSecondBottomPoint)
            {
                if(m_zigZagBottomBuffer[idxFirstBottomPoint] > m_zigZagBottomBuffer[idxSecondBottomPoint])
                    return m_zigZagBottomBuffer[idxSecondBottomPoint];
                else
                    return m_zigZagBottomBuffer[idxFirstBottomPoint];
            }
            return 0;
        }
};