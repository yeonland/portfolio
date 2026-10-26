$(function () {
    // 1. 스크롤 이벤트
    const speed = 600;

    // GNB / 로고 클릭 시 이동
    $('header .gnb a, .logo a').on('click', function (e) {
        e.preventDefault();

        const target = $(this).attr('href');

        $('html, body').stop(true, false);

        // 첫 페이지는 무조건 맨 위로 이동
        if (target === '#page01') {
            $.scrollTo(0, speed);
        } else {
            $.scrollTo(target, speed);
        }
    });

    function headerShowHide() {
        const scrollTop = $(window).scrollTop();
        const page02Top = $('#page02').offset().top;

        if (scrollTop >= page02Top - 100) {
            $('header').removeClass('header-hidden').addClass('header-visible');
        } else {
            $('header').removeClass('header-visible').addClass('header-hidden');
        }
        }

        $(window).on('scroll resize', function () {
        headerShowHide();
    });

    headerShowHide();

    // 2. 스크롤 시 메뉴 색상 자동 변경
    $(window).on('scroll', function () {
        const scrollTop = $(window).scrollTop();
        const $gnbLinks = $('.gnb li a');
        
        // 인트로 범위 내 초기화
        if (scrollTop < $('#page02').offset().top - 100) {
            $gnbLinks.each(function () {
                const img = $(this).find('img');
                img.attr('src', img.attr('src').replace('-on', '-off'));
                $(this).find('span').css('color', '#999');
            });
            return;
        }

        // 각 섹션별 색상 변경
        // [섹션, 메뉴 순서] — 프로젝트 섹션 두 개는 같은 '프로젝트' 메뉴를 켬
        [['#page02', 0], ['#page03', 1], ['#page04', 2], ['#page04-2', 2], ['#design', 3], ['#page05', 4]].forEach(([id, index]) => {
            const $section = $(id);
            if ($section.length === 0) return;
            const top = $section.offset().top - 100;
            const bottom = top + $section.outerHeight();

            if (scrollTop >= top && scrollTop < bottom) {
                $gnbLinks.each(function () {
                    const img = $(this).find('img');
                    img.attr('src', img.attr('src').replace('-on', '-off'));
                    $(this).find('span').css('color', '#999');
                });
                const $current = $gnbLinks.eq(index);
                $current.find('img').attr('src', $current.find('img').attr('src').replace('-off', '-on'));
                $current.find('span').css('color', '#F4E53B');
            }
        });
    });

    // 진행 중인 프로젝트 좌우 넘기기 (끝에서 처음으로 돌아가는 무한 넘김 + 자동 넘김)
    const $slider = $('#page04-2 .slider');
    const $track = $slider.find('.cards-container');
    const $cards = $track.find('.card');
    const $count = $('#page04-2 .slider-count');
    const $pause = $('#page04-2 .slider-pause');
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const autoDelay = 4000;
    let autoTimer = null;
    let autoOn = !reduceMotion;      // 움직임 줄이기 설정이면 자동 넘김을 끈 채로 시작
    let hovering = false;

    function cardStep() {
        return $cards.outerWidth() + parseFloat($track.css('column-gap'));
    }

    function slide(direction) {
        const track = $track[0];
        const max = track.scrollWidth - track.clientWidth;
        if (max <= 1) return;        // 모바일처럼 세로로 쌓였으면 넘길 것이 없음

        let left = track.scrollLeft + direction * cardStep();
        if (direction > 0 && track.scrollLeft >= max - 1) left = 0;     // 마지막 → 처음
        if (direction < 0 && track.scrollLeft <= 1) left = max;         // 처음 → 마지막
        track.scrollTo({left, behavior: reduceMotion ? 'auto' : 'smooth'});
    }

    // 지금 보이는 카드 범위: "1–3 / 4"
    function updateCount() {
        const step = cardStep();
        const perView = Math.max(1, Math.round(($track[0].clientWidth + 1) / step));
        const first = Math.round($track[0].scrollLeft / step) + 1;
        const last = Math.min(first + perView - 1, $cards.length);
        $count.text(`${first}–${last} / ${$cards.length}`);
    }

    function startAuto() {
        clearInterval(autoTimer);
        if (autoOn && !hovering) autoTimer = setInterval(() => slide(1), autoDelay);
    }

    function setAuto(on) {
        autoOn = on;
        $pause.attr('aria-label', on ? '자동 넘김 멈춤' : '자동 넘김 시작')
            .find('i').attr('class', on ? 'fa-solid fa-pause' : 'fa-solid fa-play');
        startAuto();
    }

    $slider.find('.slider-btn').on('click', function () {
        slide($(this).hasClass('next') ? 1 : -1);
        startAuto();                 // 직접 넘긴 직후 바로 또 넘어가지 않게 타이머 초기화
    });

    $pause.on('click', () => setAuto(!autoOn));

    // 카드를 보거나 버튼에 초점이 있는 동안에는 멈춤
    $slider.on('mouseenter focusin', () => { hovering = true; clearInterval(autoTimer); });
    $slider.on('mouseleave focusout', () => { hovering = false; startAuto(); });

    $track.on('scroll', updateCount);
    $(window).on('resize', updateCount);
    updateCount();
    setAuto(autoOn);

    // 3. 디자인 작업물 크게 보기
    const mockups = [];
    for (let row = 1; row <= 3; row++) {
        for (let col = 1; col <= 4; col++) {
            mockups.push({ src: `./project_01/img/07_${row}_${col} metapo.jpg`, alt: `소하 상품 목업 ${mockups.length + 1}` });
        }
    }

    const galleries = {
        'soha-visual': {
            title: '소하 · 브랜드 비주얼',
            groups: [
                { name: '브랜드·상품 배너', items: [{ src: './img/design/soha-banner.jpg', alt: '소하 브랜드 소개 배너와 상품 배너' }] },
                { name: '메인 비주얼', items: [1, 2, 3, 4, 5, 6].map((n) => ({ src: `./project_01/img/02_main_visual0${n}.jpg`, alt: `소하 메인 비주얼 ${n}` })) },
                { name: '상품 목업', grid: true, items: mockups }
            ]
        },
        'soha-product': {
            title: '소하 · 상품 디자인',
            groups: [{ name: '디지털 속지', items: [{ src: './img/product.jpg', alt: '일주일 플래너, 습관 트래커, 위클리 속지' }] }]
        },
        'simda': {
            title: '심다 · 저축 습관 앱 UI',
            groups: [
                { name: '앱 화면', items: [{ src: './img/design/simda-app.jpg', alt: '심다 앱 화면 흐름' }] },
                { name: '스타일 가이드', items: [{ src: './img/style_guide.jpg', alt: '심다 타이포그래피, 컬러, 버튼 스타일 가이드' }] }
            ]
        },
        'graphic': {
            title: '개인 그래픽 작업',
            groups: [
                { name: '2026 롯데자이언츠 캘린더', items: [{ src: './img/design/calendar.jpg', alt: '롯데자이언츠 팀 컬러로 만든 야구 없는 날 캘린더' }] },
                { name: '미니 가계부', grid: true, items: [
                    { src: './img/design/budget.jpg', alt: '미니 가계부' },
                    { src: './img/design/budget-black.jpg', alt: '미니 가계부 블랙' }
                ] }
            ]
        }
    };

    const $modal = $('#designModal');
    const $modalBody = $modal.find('.design-modal-body');
    let $lastTrigger = null;

    function openGallery(key, $trigger) {
        const gallery = galleries[key];
        if (!gallery) return;

        $modal.find('#designModalTitle').text(gallery.title);
        $modalBody.empty();

        gallery.groups.forEach((group) => {
            $('<h4>').text(group.name).appendTo($modalBody);
            const $wrap = $('<div>').addClass(group.grid ? 'design-modal-grid' : 'design-modal-list').appendTo($modalBody);
            group.items.forEach((item) => {
                $('<img>', { src: item.src, alt: item.alt, loading: 'lazy' }).appendTo($wrap);
            });
        });

        $lastTrigger = $trigger;
        $modal.prop('hidden', false);
        $('body').addClass('modal-open');
        $modalBody.scrollTop(0);
        $modal.find('.design-modal-close').trigger('focus');
    }

    function closeGallery() {
        $modal.prop('hidden', true);
        $('body').removeClass('modal-open');
        if ($lastTrigger) $lastTrigger.trigger('focus');
    }

    $('.design-open, .design-thumb').on('click', function () {
        openGallery($(this).data('gallery'), $(this).closest('.design-card').find('.design-open'));
    });

    $modal.find('.design-modal-close').on('click', closeGallery);

    // 바깥 어두운 영역을 누르면 닫기
    $modal.on('click', function (e) {
        if (e.target === this) closeGallery();
    });

    $(document).on('keydown', function (e) {
        if (e.key === 'Escape' && !$modal.prop('hidden')) closeGallery();
    });
})