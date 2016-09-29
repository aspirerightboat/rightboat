$ ->
  $('.berths-popup-link').each ->
    $(@).simpleAjaxLink().loadPopupOnce()
    .on 'ajax:success', (data) ->
      $.getScript('https://maps.google.com/maps/api/js?sensor=false')
      map = null
      marker = null

      initMap = ->
        map = new google.maps.Map $('#select-map').get(0),
          zoom: 5,
          center: {lat: 51.5286416, lng: -0.1015987},
          disableDoubleClickZoom: true,
          mapTypeControl: false,
          navigationControl: false,
          streetViewControl: false
        map.addListener 'click', (e) ->
          placeMarkerAndPanTo(e.latLng, map)

      placeMarkerAndPanTo = (latLng, map) ->
        marker.setMap(null) if marker
        geocorder = new (google.maps.Geocoder)
        geocorder.geocode {location: latLng}, (results, status) ->
          if status == google.maps.GeocoderStatus.OK
            if results[0]
              location = results[0].formatted_address
              $('#berth_enquiry_location').val(location)
              $('#location_address').text(location)
              $('#berth_enquiry_latitude').val(latLng.lat())
              $('#berth_enquiry_longitude').val(latLng.lng())
              marker = new google.maps.Marker({
                position: latLng,
                map: map,
                title: location
              })
              map.panTo(latLng)
            else
              alert('No result found.')
          else
            alert('Geocoder failed due to: ' + status)

      $popup = $('#berths_popup')
      window.initSlider($('.slider', $popup))
      $('.slider-length-select', $popup).sliderLengthSelect()
      $popup.on 'shown.bs.modal.rb', ->
        initMap()
        $popup.off('shown.bs.modal.rb')

      $('#berths_form').simpleAjaxForm()
      .on 'ajax:success', (e, data) ->
        $('#berths_result_popup').remove()
        $(data.show_popup).appendTo(document.body).displayPopup()
