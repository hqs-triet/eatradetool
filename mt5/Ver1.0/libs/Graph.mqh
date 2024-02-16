#include <ChartObjects\ChartObjectsLines.mqh>
#include <ChartObjects\ChartObjectsShapes.mqh>

void DrawLine(CChartObjectTrend *&line, string id, datetime date1, double price1, datetime date2, double price2)
{
    if(line != NULL && ObjectFind(0, id) >= 0)
    {
        line.SetPoint(0, date1, price1);
        line.SetPoint(1, date2, price2);
        return;
    }
    line = new CChartObjectTrend();
    line.Create(0, id, 0, date1, price1, date2, price2);
    line.Color(clrYellowGreen);
    //m_line.RayRight(true);
    line.Selectable(true);
    //m_line.Selected(true);

}
void DrawRec(CChartObjectRectangle *&rec, string id, 
             datetime date1, double price1, datetime date2, double price2, color clr)
{
    //Print("first obj=" + ObjectFind(0, id));
    if(rec != NULL && ObjectFind(0, id) >= 0)
    {
        //Print("obj=" + ObjectFind(0, id));
        rec.SetPoint(0, date1, price1);
        rec.SetPoint(1, date2, price2);
        rec.Color(clr);
        return;
    }
    //Print("new obj=" + ObjectFind(0, id));
    rec = new CChartObjectRectangle();
    rec.Create(0, id, 0, date1, price1, date2, price2);
    //m_line.Color(clrYellow);
    //m_line.RayRight(true);
    rec.Selectable(true);
    //m_rec.Selected(true);
    rec.Fill(true);
    rec.Background(true);
    rec.Color(clr);
    
}

//bool AddButton()