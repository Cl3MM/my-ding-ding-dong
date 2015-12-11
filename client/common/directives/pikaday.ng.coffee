class Pika
  constructor: ($timeout)->
    return {
      restrict: 'A'
      scope: {
        model : '='
        picker : '='
        opts : '='
      }
      link: (scope, element, attrs)->
        throw 'Missing model attribute in pikaday directive' unless attrs?.model?
        throw 'Missing picker attribute in pikaday directive' unless attrs?.picker?

        wk = moment.weekdays()
        wk.push wk.shift()
        locales =
          fr:
            previousMonth : 'Précédent'
            nextMonth     : 'Suivant'
            months        : (_.capitalize(moment().month(i).format('MMMM')) for i in [0..11])
            weekdays      : wk
            weekdaysShort : moment.weekdaysShort()

        picker = new Pikaday
          field: $(element)[0]
          format: attrs?.opts?.format ? 'DD-MM-YYYY'
          minDate: scope?.opts?.minDate ? moment().toDate()
          firstDay: attrs?.opts?.firstDay ? 1
          i18n: locales.fr
          onSelect: ->
            scope.model = angular.copy this.getMoment()

        picker.setMoment scope.model
        scope.picker = picker
    }

angular
  .module 'huezNg.common.directives'
  .directive 'pikaday', ['$timeout', Pika]

