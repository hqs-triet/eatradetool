#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
class IAlgorithm
{
    protected:
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        string m_prefixComment;
        ulong m_magicNumber;
        bool m_requireRealtime;
    public:
        virtual int Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       string prefixComment, ulong magicNumber){
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            m_prefixComment = prefixComment;
            m_magicNumber = magicNumber;
            m_requireRealtime = false;
            return INIT_SUCCEEDED;
        }
        virtual void Process(int limit) = 0;
        virtual void ProcessChartEvent(const int id,       // event id
                                const long&   lparam, // chart period
                                const double& dparam, // price
                                const string& sparam  // symbol
                               ){};
        bool RequireRealtime() {
            return m_requireRealtime;
        };
};