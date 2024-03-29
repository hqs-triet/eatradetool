#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
class ICondition
{
    protected:
        string m_symbolCurrency;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
    public:
        virtual int Init(string symbol, ENUM_TIMEFRAMES tf,
                         AllSeriesInfo &infoCurrency){
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_infoCurrency = infoCurrency;
            return INIT_SUCCEEDED;
        }
        virtual void Process(int limit) = 0;
        virtual bool IsMatched(int limit, int flag) = 0;
        virtual bool IsMatched(int limit, int flag1, int flag2) {
            return false;
        }
};