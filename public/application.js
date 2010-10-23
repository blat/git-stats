$(document).ready(function() {
    $('#repositories').change(function() {
        if ($(this).val()) {
            window.location.href = '/project/' + $(this).val() + ($('#since').val() ? '/' + $('#since').val() : '');
        } else {
            window.location.href = ($('#since').val() ? '/' + $('#since').val() : '');
        }
    });

    $('#since').change(function() {
        if (document.URL.match('/project')) {
            window.location.href = '/project/' + $('#repositories').val() + '/' + $(this).val();
        } else {
            window.location.href = '/' + $(this).val();
        }
    });
});
