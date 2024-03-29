
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "ICondition.mqh"
#resource "\\Indicators\\Examples\ZigZagColor.ex5"
#include <ChartObjects\ChartObjectsLines.mqh>
// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================
enum ENUM_EMAFAN
{
    ENUM_EMAFAN_UP = 1,
    ENUM_EMAFAN_DOWN = 2
};
// ===================================================================
// Class xử lý phát hiện các EMA bung ra, thừa kế ICondition
// ===================================================================
class CEmaFanOut: public ICondition
{
    struct dynBuff
    {
        double data[];
    };
    private:
        
        dynBuff m_emaBuffers[];
        int m_emaHandlers[];
        int m_totalEma;
    public:
        // =======================================================
        // Khởi tạo các thông số
        // =======================================================
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, uint &emaPeriods[])
        {
            ICondition::Init(symbol, tf, infoCurrency);

            // Sắp xếp tăng dần
            ArraySort(emaPeriods);
            int emaLen = ArraySize(emaPeriods);
            int realEmaLen = 0;
            ArrayResize(m_emaHandlers, emaLen);
            for(int idx = 0; idx < emaLen; idx++) 
            {
                if(emaPeriods[idx] > 0)
                {
                    m_emaHandlers[idx] = iMA(m_symbolCurrency, m_tf, emaPeriods[idx], 0, MODE_EMA, PRICE_CLOSE);
                    if(m_emaHandlers[idx] == INVALID_HANDLE)
                    {
                        Print("Không khởi tạo được EMA" + emaPeriods[idx]);
                        return INIT_FAILED;
                    }
                    realEmaLen++;
                }
            }
            ArrayResize(m_emaBuffers, realEmaLen);
            for(int idx = 0; idx < realEmaLen; idx++)
            {
                ArraySetAsSeries(m_emaBuffers[idx].data, true);
            }
            m_totalEma = realEmaLen;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            for(int idx = 0; idx < m_totalEma; idx++)
            {
                CopyBuffer(m_emaHandlers[idx], 0, 0, bars, m_emaBuffers[idx].data);
            }
        }
        
        // =======================================================
        // Phát hiện các EMA đang tỏa ra
        // =======================================================
        bool IsMatched(int limit, int flag)
        {
            // Vị trí 1 thì EMA được tỏa ra định vị trí rõ ràng
            // Vị trí 2 thì EMA vẫn còn giao cắt, vị trí chưa rõ ràng
            return IsMatched(limit, flag, 1) && !IsMatched(limit, flag, 2);
        }
        // -----------------------------------------------
        // flag2: vị trí index chỉ định
        // -----------------------------------------------
        bool IsMatched(int limit, int flag1, int flag2)
        {
            bool result = true;
            for(int idx = 0; idx < m_totalEma - 1; idx++)
            {
                if(flag1 == (int)ENUM_EMAFAN_UP)
                {
                    if(m_emaBuffers[idx].data[flag2] <= m_emaBuffers[idx + 1].data[flag2])
                    {
                        result = false;
                        break;
                    }
                }
                else if(flag1 == (int)ENUM_EMAFAN_DOWN)
                {
                    if(m_emaBuffers[idx].data[flag2] >= m_emaBuffers[idx + 1].data[flag2])
                    {
                        result = false;
                        break;
                    }
                }
                else
                    result = false;
            }
            return result;
        }
        double getMaxEma()
        {
            double max = m_emaBuffers[0].data[1];
            for(int idx = 1; idx < m_totalEma; idx++)
            {
                if(m_emaBuffers[idx].data[1] > max)
                    max = m_emaBuffers[idx].data[1];
            }
            return max;
        }
        double getMinEma()
        {
            double min = m_emaBuffers[0].data[1];
            for(int idx = 1; idx < m_totalEma; idx++)
            {
                if(m_emaBuffers[idx].data[1] < min)
                    min = m_emaBuffers[idx].data[1];
            }
            return min;
        }
    protected:
        
};