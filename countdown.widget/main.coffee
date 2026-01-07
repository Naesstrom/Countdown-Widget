MILLIS_IN_DAY: 24 * 60 * 60 * 1000
MILLIS_IN_HOUR: 60 * 60 * 1000
MILLIS_IN_MINUTE: 60 * 1000
MILLIS_IN_SECOND: 1000

# Lägg till röda dagar här (format: ÅÅÅÅ-MM-DD)
excludedDates: [
  "2025-01-01", # Nyårsdagen
  "2025-01-06", # Trettondedag jul
  "2025-05-01", # Första maj
]

# Lägg till längre perioder här (t.ex. semester eller lov)
excludedPeriods: [
  { start: "2025-07-01", end: "2025-07-31" } # Exempel: Juli månad
]

countdowns: [
  label: "New Year's Day"
  time: "Jan 1, 2026"
,
  label: "Viktigt Projekt"
  time: "Feb 13, 2025"
]

command: ""
refreshFrequency: 1000

style: """
  # (Samma stil som tidigare...)
  *
    margin 0
    padding 0
  #container
    background rgba(#000, .5)
    margin 10px 10px 15px
    padding 10px
    border-radius 5px
    color rgba(#fff, .9)
    font-family Helvetica Neue
  span
    font-size 14pt
    font-weight bold
  ul
    list-style none
  li
    padding 10px
    &:not(:last-child)
      border-bottom solid 1px white
  thead
    font-size 8pt
    font-weight bold
    td
      width 60px
  tbody
    font-size 12pt
  td
    text-align center
"""

render: -> """
  <div id="container">
    <ul></ul>
  </div>
"""

afterRender: ->
  for countdown in @countdowns
    countdown.millis = new Date(countdown.time).getTime()

update: (output, domEl) ->
  $countdownList = $(domEl).find("#container").find("ul")
  $countdownList.empty()

  now = new Date()
  nowTime = now.getTime()

  for countdown in @countdowns
    targetTime = countdown.millis
    
    if targetTime <= nowTime
      continue

    # Beräkna total tidsskillnad
    rawDiff = targetTime - nowTime
    excludedMillis = 0
    
    # Loopa igenom varje dag för att hitta tid som ska dras av
    checkDate = new Date(nowTime)
    # Vi kollar dag för dag från 'nu' till 'mål'
    while checkDate.getTime() <= targetTime
      # Kolla om det är helg (Lördag = 6, Söndag = 0)
      isWeekend = checkDate.getDay() == 0 or checkDate.getDay() == 6
      
      # Kolla om det är en röd dag
      dateStr = checkDate.toISOString().split('T')[0]
      isHoliday = dateStr in @excludedDates
      
      # Kolla om dagen ingår i en exkluderad period
      isPeriod = false
      for period in @excludedPeriods
        pStart = new Date(period.start).setHours(0,0,0,0)
        pEnd = new Date(period.end).setHours(23,59,59,999)
        if checkDate.getTime() >= pStart and checkDate.getTime() <= pEnd
          isPeriod = true
          break

      if isWeekend or isHoliday or isPeriod
        # Räkna ut hur mycket av just denna dag som ska dras av
        dayStart = new Date(checkDate).setHours(0,0,0,0)
        dayEnd = new Date(checkDate).setHours(23,59,59,999)
        
        # Vi drar bara av den del av dagen som faktiskt ligger inom vårt countdown-intervall
        overlapStart = Math.max(dayStart, nowTime)
        overlapEnd = Math.min(dayEnd, targetTime)
        
        if overlapEnd > overlapStart
          excludedMillis += (overlapEnd - overlapStart)

      # Gå till nästa dag
      checkDate.setDate(checkDate.getDate() + 1)
      checkDate.setHours(0,0,0,0)

    # Den faktiska tiden kvar efter avdrag
    millisUntil = rawDiff - excludedMillis

    # Konvertera till dagar, timmar, minuter, sekunder
    timeUntil = {}
    timeUntil.days = millisUntil // @MILLIS_IN_DAY
    millisUntil %= @MILLIS_IN_DAY
    timeUntil.hours = millisUntil // @MILLIS_IN_HOUR
    millisUntil %= @MILLIS_IN_HOUR
    timeUntil.minutes = millisUntil // @MILLIS_IN_MINUTE
    millisUntil %= @MILLIS_IN_MINUTE
    timeUntil.seconds = millisUntil // @MILLIS_IN_SECOND

    $countdownList.append("""
      <li>
        <span>#{countdown.label}</span>
        <table>
          <thead>
            <tr>
              <td>DAGAR</td>
              <td>TIMMAR</td>
              <td>MIN</td>
              <td>SEK</td>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>#{timeUntil.days}</td>
              <td>#{timeUntil.hours}</td>
              <td>#{timeUntil.minutes}</td>
              <td>#{timeUntil.seconds}</td>
            </tr>
          </tbody>
        </table>
      </li>
    """)
