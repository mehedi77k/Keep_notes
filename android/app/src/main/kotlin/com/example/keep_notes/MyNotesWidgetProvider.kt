package com.example.keep_notes

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

abstract class BaseMyNotesWidgetProvider(
    private val layoutResId: Int,
) : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, layoutResId).apply {
            val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, launchIntent)

            val quickAddIntent =
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mynotes://new-note"),
                )
            setOnClickPendingIntent(R.id.widget_quick_add, quickAddIntent)

            setTextViewText(
                R.id.widget_title,
                widgetData.getString("my_notes_widget_title", "My Notes"),
            )
            setTextViewText(
                R.id.widget_message,
                widgetData.getString("my_notes_widget_message", "No notes yet. Tap to open My Notes."),
            )
            setTextViewText(
                R.id.widget_count,
                widgetData.getString("my_notes_widget_count", "0 active notes"),
            )
            setTextViewText(
              R.id.widget_reminder,
              widgetData.getString("my_notes_widget_reminder", "No upcoming reminders"),
            )
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}

class MyNotesSmallWidgetProvider : BaseMyNotesWidgetProvider(R.layout.my_notes_widget_small)

class MyNotesWidgetProvider : BaseMyNotesWidgetProvider(R.layout.my_notes_widget)

class MyNotesLargeWidgetProvider : BaseMyNotesWidgetProvider(R.layout.my_notes_widget_large)
