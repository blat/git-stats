$(document).ready(function() {
    $('#repositories').change(function() {
        window.location.href = '/' + $(this).val() + ($('#since').val() ? '/' + $('#since').val() : '');
    });

    $('#since').change(function() {
        window.location.href = '/' + $('#repositories').val() + '/' + $(this).val();
    });
});
