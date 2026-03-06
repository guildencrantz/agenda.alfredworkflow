var UpcomingEvents = (function() {
  return {
    get: function(todayOnly, listName, limit) {
      var app = Application.currentApplication();
      app.includeStandardAdditions = true;

      const flags = todayOnly ? '--start-of-day --limit 0' : `--limit ${limit}`
      let excludeFlags = ''
      try {
        const patterns = $.getenv('event_exclude_patterns')
        if (patterns) {
          excludeFlags = patterns.split(',')
            .map(p => p.trim()).filter(p => p.length > 0)
            .map(p => ` --exclude "${p}"`).join('')
        }
      } catch(_) {}
      const events = app.doShellScript(`./agenda events${listName ? ` "${listName}"`: ''} ${flags}${excludeFlags};`)

      const todayTS = new Date()
      const todayDate = todayTS.getDate() < 10 ? `0${todayTS.getDate()}` : todayTS.getDate();
      const todayMonth = (todayTS.getMonth() + 1) < 10 ? `0${(todayTS.getMonth() + 1)}` : todayTS.getMonth() + 1;
      const todayDateString = `${todayTS.getFullYear()}-${todayMonth}-${todayDate}`

      const tomorrowTS = new Date()
      tomorrowTS.setDate(tomorrowTS.getDate() + 1)
      const tomorrowDate = tomorrowTS.getDate() < 10 ? `0${tomorrowTS.getDate()}` : tomorrowTS.getDate();
      const tomorrowMonth = (tomorrowTS.getMonth() + 1) < 10 ? `0${(tomorrowTS.getMonth() + 1)}` : tomorrowTS.getMonth() + 1;
      const tomorrowDateString = `${tomorrowTS.getFullYear()}-${tomorrowMonth}-${tomorrowDate}`

      const eventData = events === '' ? [] : events.split('\r')
      let items = []

      eventData.forEach(ri => {
        let parsed = JSON.parse(ri)
        parsed = {
          ...parsed,
          allDay: parsed.allDay === 'true',
        }

        let startDate = parsed.start
        let endDate = parsed.end

        const eventTS = new Date(parsed.start.replace(' ', 'T'))
        const endTS = new Date(parsed.end.replace(' ', 'T'))
        const isOverdue = eventTS < todayTS
        const isToday = parsed.start.includes(todayDateString)
        const isTomorrow = parsed.start.includes(tomorrowDateString)

        const [eventStartDate, eventStartTime] = startDate.split(' ')
        const [eventEndDate, eventEndTime] = endDate.split(' ')

        const isAllDay = parsed.allDay
        const isSameDay = !isAllDay && eventStartDate === eventEndDate

        const calendarURI = encodeURIComponent(parsed.calendar)
        const titleURI = encodeURIComponent(parsed.title)
        const eventTSiso = eventTS.toISOString().replace('.000Z', 'Z')

        if (todayOnly && !parsed.start.includes(todayDateString)) return
        if (!todayOnly && endTS < todayTS) return
        let dateOutput = parsed.allDay ? 'All Day' : eventStartTime
        let sort = parsed.allDay ? 'All Day' : eventStartTime
        if (!todayOnly) {
          sort = parsed.start
          if (parsed.allDay)
          {
            dateOutput = `${eventStartDate} All Day`
          } else {
            dateOutput = parsed.start
          }
        }

        let icon = 'calendar'
        const titleLC = parsed.title.toLowerCase()
        if (titleLC.includes('birthday'))
        {
          icon = 'birthday'
        } else if (titleLC.includes('holiday'))
        {
          icon = 'holiday'
        }

        if (isToday)
        {
          startDate = parsed.start.replace(todayDateString, 'Today at')
          icon = 'today'
        } else if (isTomorrow)
        {
          startDate = parsed.start.replace(tomorrowDateString, 'Tomorrow at')
        }

        startDate = startDate.replace(' at 00:00', '')

        let subtitle = `${startDate}`
        if (isAllDay) {
          subtitle = 'All Day'
          if (isToday) {
            subtitle += ' Today'
          } else if (isTomorrow) {
            subtitle += ' Tomorrow'
          } else {
            subtitle = `${eventStartDate} All Day`
          }
        } else if (isSameDay && isToday) {
          subtitle += ` until ${eventEndTime}`
        } else if (isSameDay && isTomorrow)
        {
          subtitle += ` - ${eventEndTime}`
          subtitle = subtitle.replace('Tomorrow at', 'Tomorrow')
        } else if (!isSameDay) {
          subtitle += ` - ${eventEndDate} ${eventEndTime}`
        } else {
          subtitle += ` - ${eventEndTime}`
        }

        if (parsed.location)
        {
          subtitle += ` @ ${parsed.location}`
        }

        subtitle = `${subtitle}${listName ? '' : ` / ${parsed.calendar}`} `

        if (todayOnly) subtitle = subtitle.replace('Today at ', '')

        busycalURI = `busycalevent://find/${encodeURIComponent(parsed.calendar)}/${encodeURIComponent(parsed.title)}/${encodeURIComponent(eventTSiso)}`
        // If the current time is in the meeting time range, append meeting_url to arg
        const findURI = `find/${encodeURIComponent(parsed.calendar)}/${encodeURIComponent(parsed.title)}/${encodeURIComponent(eventTSiso)}`
        let arg = $.getenv('use_busycal') === 'true' ? `c:${busycalURI}` : `c:${findURI}`
        if (eventTS < todayTS && todayTS < endTS) {
          arg += `,${parsed.meeting_url}`
        }

        items.push({
          title: parsed.title,
          subtitle,
          arg: arg,
          autocomplete: parsed.title,
          icon: {
            path: `icons/${icon}.png`,
          },
          sort,
          mods: {
            cmd: {
              arg: parsed.meeting_url,
              subtitle: `Join ${parsed.meeting_url}`
            },
            alt: {
              arg: `${parsed.title}`,
              subtitle: `Copy title to clipboard`
            }
          }
        })
      })

      return items
    },
  };
})();

// Add AMD compatibility.
if (typeof define === 'function' && define.amd) {
  define(UpcomingEvents);
}
// Add CommonJS compatibility.
else if (typeof module !== 'undefined' && module.exports) {
  module.exports = UpcomingEvents;
}
