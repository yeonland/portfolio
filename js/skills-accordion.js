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

    // 가벼운 별 배경 (외부 라이브러리 불필요)
    const starsHost = $section.find('.skills-stars')[0];
    if (starsHost && !starsHost.children.length) {
        const fragment = document.createDocumentFragment();
        const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        const count = reduceMotion ? 16 : 42;
        for (let i = 0; i < count; i++) {
            const star = document.createElement('span');
            star.className = 'skills-star';
            // 일정한 위치: 페이지 재진입 시 별이 갑자기 재배치되지 않음
            const x = (i * 67.37 + 13) % 100;
            const y = (i * 43.19 + 17) % 100;
            star.style.setProperty('--x', x.toFixed(2) + '%');
            star.style.setProperty('--y', y.toFixed(2) + '%');
            star.style.setProperty('--size', (1 + (i % 4) * .55).toFixed(2) + 'px');
            star.style.setProperty('--duration', (2.7 + (i % 7) * .61).toFixed(2) + 's');
            star.style.setProperty('--delay', (-i * .29).toFixed(2) + 's');
            fragment.appendChild(star);
        }
        starsHost.appendChild(fragment);
    }
});
