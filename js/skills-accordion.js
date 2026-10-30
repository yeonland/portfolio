/* Portfolio / 기술 역량 : jQuery 사용, 기존 main.js 동작 변경 없음 */
$(function () {
    const $section = $('#page03.skills-section');
    if (!$section.length) return;

    const $cards = $section.find('.skill-category');
    const $toggles = $section.find('.skill-toggle');

    function setOpen($card, open) {
        $card.toggleClass('is-open', open);
        $card.find('.skill-toggle').attr('aria-expanded', String(open));
    }

    // 기본: 첫 번째 카드만 열림. 하나를 열면 나머지는 닫힘.
    $cards.each(function (index) { setOpen($(this), index === 0); });

    $toggles.on('click', function () {
        const $card = $(this).closest('.skill-category');
        const nextOpen = !$card.hasClass('is-open');
        $cards.each(function () { setOpen($(this), false); });
        if (nextOpen) setOpen($card, true);
    });
});
