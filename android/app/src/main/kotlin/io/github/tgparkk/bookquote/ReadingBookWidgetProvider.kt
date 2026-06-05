package io.github.tgparkk.bookquote

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 홈 화면 위젯 '읽고 있는 책' (HW-D).
 *
 * 가장 최근 시작한 책의 표지 + 제목·저자 + 'N일째 읽는 중' + 한 줄 적기 CTA.
 * 데이터는 Flutter(HomeWidgetService.pushReadingBook)가 SharedPreferences로 전달.
 * 표지는 앱이 받아 저장한 파일 경로(reading_cover_path)를 비트맵으로 디코드한다.
 * 읽는 책이 없으면(title 비어있음) 빈 상태 안내. 탭 → 그 책 '한 줄 적기'(글귀 위젯과 동일 채널).
 */
class ReadingBookWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.reading_book_widget).apply {
                val title = widgetData.getString("reading_book_title", null) ?: ""
                val author = widgetData.getString("reading_book_author", null) ?: ""
                val daysLabel = widgetData.getString("reading_days_label", null) ?: ""
                val bookId = widgetData.getString("reading_book_id", null) ?: ""
                val coverPath = widgetData.getString("reading_cover_path", null)

                if (title.isBlank()) {
                    // 읽기 시작한 책 없음 — 시작 유도.
                    setTextViewText(R.id.reading_title, "읽기 시작한 책이 없어요")
                    setTextViewText(R.id.reading_author, "")
                    setTextViewText(R.id.reading_days, "")
                    setTextViewText(R.id.reading_cta, "＋ 시작한 책 알려주기")
                    setViewVisibility(R.id.reading_cover, View.GONE)
                } else {
                    setTextViewText(R.id.reading_title, title)
                    setTextViewText(R.id.reading_author, author)
                    setTextViewText(R.id.reading_days, daysLabel)
                    setTextViewText(R.id.reading_cta, "＋ 한 줄 적기")
                    val bmp = if (!coverPath.isNullOrBlank()) {
                        BitmapFactory.decodeFile(coverPath)
                    } else {
                        null
                    }
                    if (bmp != null) {
                        setImageViewBitmap(R.id.reading_cover, bmp)
                        setViewVisibility(R.id.reading_cover, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.reading_cover, View.GONE)
                    }
                }

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://quote?bookId=$bookId"),
                )
                setOnClickPendingIntent(R.id.reading_root, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
