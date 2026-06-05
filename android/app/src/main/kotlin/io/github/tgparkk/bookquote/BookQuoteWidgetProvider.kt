package io.github.tgparkk.bookquote

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 홈 화면 위젯 '이 책의 한 줄' (HW-A 스캐폴드).
 *
 * home_widget 플러그인이 Flutter에서 보낸 데이터를 SharedPreferences(widgetData)로
 * 전달한다. 키: book_title / book_author / quote_text. (HW-B에서 book_id·딥링크 추가)
 * 데이터 미설정 시 한국어 기본값이 렌더돼 위젯 추가 직후에도 화면이 비지 않는다.
 *
 * 탭 = 앱 실행(HomeWidgetLaunchIntent). 특정 책 '한 줄 적기'로의 딥링크 라우팅은 HW-B,
 * OS 다크 테마 추종·표지 이미지는 HW-B/HW-C에서.
 */
class BookQuoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.bookquote_widget).apply {
                val title = widgetData.getString("book_title", null) ?: "읽고 있는 책"
                val author = widgetData.getString("book_author", null) ?: ""
                val quote = widgetData.getString("quote_text", null)
                    ?: "이 책에서 마음에 남은 한 줄을 적어보세요."

                setTextViewText(R.id.widget_book_title, title)
                setTextViewText(
                    R.id.widget_book_author,
                    if (author.isBlank()) "" else "— $author",
                )
                setTextViewText(R.id.widget_quote, "“$quote”")

                // 위젯 탭 → 앱 실행 + bookId 전달. Dart(HomeWidgetService)가
                // widgetClicked로 받아 `/quote/new?bookId=`로 라우팅한다(bookId 없으면 홈).
                val bookId = widgetData.getString("book_id", null) ?: ""
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://quote?bookId=$bookId"),
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
