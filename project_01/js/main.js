document.addEventListener('DOMContentLoaded', function () {
    // slideDown
    function slideDown(element, duration = 300) {
        if (!element) return;

        element.getAnimations().forEach(function (animation) {
            animation.cancel();
        });

        element.style.display = 'block';

        const height = element.scrollHeight;

        const animation = element.animate(
            [
                {
                    height: '0',
                    opacity: 0,
                    overflow: 'hidden'
                },
                {
                    height: height + 'px',
                    opacity: 1,
                    overflow: 'hidden'
                }
            ],
            {
                duration: duration,
                easing: 'ease'
            }
        );

        animation.onfinish = function () {
            element.style.height = '';
            element.style.opacity = '';
            element.style.overflow = '';
        };
    }

    // slideUp
    function slideUp(element, duration = 300) {
        if (!element) return;

        element.getAnimations().forEach(function (animation) {
            animation.cancel();
        });

        const height = element.offsetHeight;

        const animation = element.animate(
            [
                {
                    height: height + 'px',
                    opacity: 1,
                    overflow: 'hidden'
                },
                {
                    height: '0',
                    opacity: 0,
                    overflow: 'hidden'
                }
            ],
            {
                duration: duration,
                easing: 'ease'
            }
        );

        animation.onfinish = function () {
            element.style.display = 'none';
            element.style.height = '';
            element.style.opacity = '';
            element.style.overflow = '';
        };
    }

    // fadeOut
    function fadeOut(element, duration = 300) {
        if (!element) return;

        element.getAnimations().forEach(function (animation) {
            animation.cancel();
        });

        const animation = element.animate(
            [
                { opacity: 1 },
                { opacity: 0 }
            ],
            {
                duration: duration,
                easing: 'ease'
            }
        );

        animation.onfinish = function () {
            element.style.display = 'none';
            element.style.opacity = '';
        };
    }

    // 1~2. 장바구니 · 최근 본 상품 팝업: 마우스 · 포커스로 열고, 벗어나면 1초 뒤 닫기
    // (버튼 → 팝업으로 옮겨 가는 사이에 닫히지 않도록 다시 들어오면 닫기를 취소)
    function bindPopup(button, box) {
        if (!button || !box) return null;

        let closeTimer = null;
        let isOpen = false;

        function open() {
            clearTimeout(closeTimer);
            if (!isOpen) slideDown(box, 300);
            isOpen = true;
        }

        function closeLater() {
            clearTimeout(closeTimer);
            closeTimer = setTimeout(function () {
                isOpen = false;
                slideUp(box, 300);
            }, 1000);
        }

        [button, box].forEach(function (target) {
            target.addEventListener('mouseenter', open);
            target.addEventListener('mouseleave', closeLater);
            target.addEventListener('focusin', open);
            target.addEventListener('focusout', closeLater);
        });

        // 아이콘 링크(href="#")를 눌러도 페이지 맨 위로 튀지 않게
        button.querySelector('a').addEventListener('click', function (event) {
            event.preventDefault();
            open();
        });

        return { open: open, closeLater: closeLater };
    }

    const cartBox = document.querySelector('.cart_box');
    const recentBox = document.querySelector('.recent_box');

    const cartPopup = bindPopup(document.querySelector('.btn_cart'), cartBox);
    bindPopup(document.querySelector('.btn_recent'), recentBox);

    // ※ 장바구니 · 최근 본 상품 저장 (브라우저 localStorage, 최대 3개)
    const CART_KEY = 'soha_cart';
    const RECENT_KEY = 'soha_recent';
    const ORDER_KEY = 'soha_order';
    const MAX_ITEMS = 3;
    // 페이지마다 폴더 깊이가 달라서 main.js 주소로 사이트 루트를 구함
    const rootUrl = document
        .querySelector('script[src*="js/main.js"]')
        .src.replace(/js\/main\.js.*$/, '');

    function loadItems(key) {
        try {
            return JSON.parse(localStorage.getItem(key)) || [];
        } catch (error) {
            return [];
        }
    }

    function saveItems(key, items) {
        try {
            localStorage.setItem(key, JSON.stringify(items));
        } catch (error) {
            // 저장이 막힌 브라우저(사생활 보호 모드 등)에서는 이번 페이지에서만 반영
        }
    }

    function formatPrice(price) {
        return price ? price.toLocaleString() + '원' : '무료';
    }

    function priceFromText(element) {
        // 할인 상품은 <del>/<span>에 정가가 있어서 바깥 텍스트(판매가)만 읽음
        const text = Array.from(element.childNodes)
            .filter(function (node) {
                return node.nodeType === Node.TEXT_NODE;
            })
            .map(function (node) {
                return node.textContent;
            })
            .join('');

        return Number(text.replace(/\D/g, ''));
    }

    // 모바일 메뉴 (☰, 1023px 이하): 헤더의 PC 메뉴 링크를 읽어 만들어서 페이지마다 경로가 자동으로 맞음
    const menuToggle = document.querySelector('.menu_toggle');
    const pcMenu = document.querySelector('.header .gnb');
    let menuRecentList = null;

    if (menuToggle && pcMenu) {
        const dim = document.createElement('div');
        dim.className = 'm_menu_dim';

        const menu = document.createElement('nav');
        menu.className = 'm_menu';
        menu.id = 'm_menu';
        menu.setAttribute('aria-label', '전체 메뉴');
        menu.inert = true;
        menu.innerHTML =
            '<div class="m_menu_head"><p>메뉴</p>' +
            '<button type="button" class="m_menu_close" aria-label="메뉴 닫기"><i class="fa-solid fa-xmark"></i></button></div>' +
            '<ul class="m_menu_list"></ul>' +
            '<div class="m_menu_recent"><p class="m_menu_tit">최근 본 상품</p><ul></ul></div>' +
            '<div class="m_menu_help"></div>';

        const list = menu.querySelector('.m_menu_list');
        const here = location.href.split('#')[0].split('?')[0];

        function menuLink(source, text) {
            const link = document.createElement('a');
            // 현재 페이지 메뉴는 PC에서 href="#"로 걸려 있어서 지금 주소로 바꿈
            const isSelf = source.getAttribute && source.getAttribute('href') === '#';
            link.href = isSelf ? here : source.href;
            link.textContent = text || source.textContent.trim();
            if (link.href === here) link.setAttribute('aria-current', 'page');
            return link;
        }

        // 디지털 문구 하위 카테고리: 페이지마다 PC 하위 메뉴가 있기도 없기도 해서 목록을 고정해 두고 경로만 계산
        const productCategories = [
            ['all', '전체'], ['diary', '다이어리'], ['planner', '플래너'],
            ['journal', '저널'], ['sticker', '스티커'], ['free', '무료']
        ];

        pcMenu.querySelectorAll(':scope > span').forEach(function (item, index) {
            const mainLink = item.querySelector(':scope > a');
            const li = document.createElement('li');

            if (item.classList.contains('product')) {
                // 하위 메뉴가 있는 항목(디지털 문구)은 눌러서 펼치기
                const toggle = document.createElement('button');
                toggle.type = 'button';
                toggle.className = 'm_menu_sub_toggle';
                toggle.setAttribute('aria-expanded', 'false');
                toggle.setAttribute('aria-controls', 'm_menu_sub' + index);
                toggle.innerHTML = '<span></span><i class="fa-solid fa-chevron-down"></i>';
                toggle.querySelector('span').textContent = mainLink.textContent.trim();

                const sub = document.createElement('ul');
                sub.className = 'm_menu_sub';
                sub.id = 'm_menu_sub' + index;

                // 메뉴 링크(.../2_product/all/index.html)에서 2_product 폴더 경로를 구함
                const productRoot = mainLink.href.replace(/[^/]+\/index\.html$/, '');

                productCategories.forEach(function (category) {
                    const subLi = document.createElement('li');
                    subLi.appendChild(menuLink(
                        { href: productRoot + category[0] + '/index.html', textContent: category[1] }
                    ));
                    sub.appendChild(subLi);
                });

                toggle.addEventListener('click', function () {
                    const expanded = toggle.getAttribute('aria-expanded') === 'true';
                    toggle.setAttribute('aria-expanded', String(!expanded));
                });

                li.appendChild(toggle);
                li.appendChild(sub);
            } else {
                li.appendChild(menuLink(mainLink));
            }

            list.appendChild(li);
        });

        const help = menu.querySelector('.m_menu_help');
        [
            { href: rootUrl + 'sub/howtouse/index.html', text: '사용법 알아보기' },
            { href: rootUrl + 'sub/4_faq/index.html', text: '고객센터' }
        ].forEach(function (item) {
            const link = document.createElement('a');
            link.href = item.href;
            link.textContent = item.text;
            help.appendChild(link);
        });

        menuRecentList = menu.querySelector('.m_menu_recent ul');

        document.body.appendChild(dim);
        document.body.appendChild(menu);

        const closeButton = menu.querySelector('.m_menu_close');
        const chatCheck = document.querySelector('#chat_chk');

        function openMenu() {
            if (chatCheck) chatCheck.checked = false;   // 채팅창이 메뉴 위에 겹치지 않게
            menu.inert = false;
            menu.classList.add('open');
            dim.classList.add('open');
            document.body.classList.add('m_menu_on');
            menuToggle.setAttribute('aria-expanded', 'true');
            // 숨김(visibility)이 풀린 다음 프레임에 포커스를 옮김
            requestAnimationFrame(function () {
                closeButton.focus();
            });
        }

        function closeMenu() {
            if (!menu.classList.contains('open')) return;
            menu.inert = true;
            menu.classList.remove('open');
            dim.classList.remove('open');
            document.body.classList.remove('m_menu_on');
            menuToggle.setAttribute('aria-expanded', 'false');
            menuToggle.focus();
        }

        menuToggle.addEventListener('click', openMenu);
        closeButton.addEventListener('click', closeMenu);
        dim.addEventListener('click', closeMenu);
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') closeMenu();
        });
        // 열어 둔 채 PC 폭으로 넓어지면 닫기
        window.matchMedia('(min-width: 1024px)').addEventListener('change', function (event) {
            if (event.matches) closeMenu();
        });
    }

    function renderMenuRecent(items) {
        if (!menuRecentList) return;

        menuRecentList.innerHTML = '';

        if (!items.length) {
            const empty = document.createElement('li');
            empty.className = 'empty';
            empty.textContent = '최근 본 상품이 없어요.';
            menuRecentList.appendChild(empty);
            return;
        }

        items.forEach(function (item) {
            const li = document.createElement('li');
            const link = document.createElement('a');
            const img = document.createElement('img');
            const name = document.createElement('span');

            link.href = item.link;
            img.src = item.img;
            img.alt = '';
            name.textContent = item.name;

            link.appendChild(img);
            link.appendChild(name);
            li.appendChild(link);
            menuRecentList.appendChild(li);
        });
    }

    // 장바구니 개수 (모바일 헤더에서만 보임)
    const cartButton = document.querySelector('.btn_cart');
    let cartCount = null;

    if (cartButton) {
        cartCount = document.createElement('span');
        cartCount.className = 'cart_count';
        cartCount.setAttribute('aria-hidden', 'true');
        cartButton.appendChild(cartCount);
    }

    function renderCartCount(items) {
        if (!cartCount) return;
        cartCount.textContent = items.length;
        cartCount.hidden = !items.length;
        cartButton.querySelector('a').setAttribute('aria-label', '장바구니 (' + items.length + '개)');
    }

    // 헤더 팝업 그리기
    function renderPopup(box, items, emptyText) {
        if (!box) return;

        const button = box.querySelector(':scope > button');

        box.querySelectorAll('.product_box, .empty').forEach(function (el) {
            el.remove();
        });

        if (!items.length) {
            const empty = document.createElement('p');
            empty.className = 'empty';
            empty.textContent = emptyText;
            box.insertBefore(empty, button);
        }

        items.forEach(function (item, index) {
            const productBox = document.createElement('div');
            productBox.className =
                'product_box' + (index === 1 ? ' second' : '');
            productBox.innerHTML =
                '<a><div class="popup_img"><img alt=""></div>' +
                '<div class="popup_txt"><p></p><p></p></div></a>';
            productBox.querySelector('a').href = item.link;
            productBox.querySelector('img').src = item.img;

            const texts = productBox.querySelectorAll('.popup_txt p');
            texts[0].textContent = item.name;
            texts[1].textContent = formatPrice(item.price);

            box.insertBefore(productBox, button);
        });

        button.disabled = !items.length;
    }

    function renderPopups() {
        const cart = loadItems(CART_KEY);
        const recent = loadItems(RECENT_KEY);

        renderPopup(cartBox, cart, '장바구니가 비어 있어요.');
        renderPopup(recentBox, recent, '최근 본 상품이 없어요.');
        renderCartCount(cart);
        renderMenuRecent(recent);
    }

    // 담은 직후 잠깐 열었다가 1초 뒤 닫기 (그 사이 마우스를 올리면 계속 열림)
    function showCartBriefly() {
        if (!cartPopup) return;
        cartPopup.open();
        cartPopup.closeLater();
    }

    // 담기에 성공하면 true
    function addToCart(item, silent) {
        const cart = loadItems(CART_KEY);

        if (cart.some(function (cartItem) {
            return cartItem.name === item.name;
        })) {
            if (!silent) alert('이미 장바구니에 담긴 상품이에요.');
            return !!silent;
        }

        if (cart.length >= MAX_ITEMS) {
            alert('장바구니에는 최대 ' + MAX_ITEMS + '개까지 담을 수 있어요.');
            return false;
        }

        cart.push(item);
        saveItems(CART_KEY, cart);
        renderPopups();

        if (!silent) showCartBriefly();

        return true;
    }

    function addToRecent(item) {
        const recent = loadItems(RECENT_KEY).filter(function (recentItem) {
            return recentItem.name !== item.name;
        });

        recent.unshift(item);
        saveItems(RECENT_KEY, recent.slice(0, MAX_ITEMS));
        renderPopups();
    }

    renderPopups();

    // 장바구니 팝업: 결제하기
    if (cartBox) {
        cartBox.querySelector(':scope > button').addEventListener('click', function () {
            location.href = rootUrl + 'sub/checkout/index.html';
        });
    }

    // 최근 본 상품 팝업: 모두 담기
    if (recentBox) {
        const recentButton = recentBox.querySelector(':scope > button');
        recentButton.textContent = '모두 담기';

        recentButton.addEventListener('click', function () {
            const added = loadItems(RECENT_KEY).every(function (item) {
                return addToCart(item, true);
            });

            if (added) showCartBriefly();
        });
    }

    // 상품 카드: 담기 버튼 + 클릭하면 최근 본 상품에 기록
    function getCardItem(card) {
        const img = card.querySelector('img');
        const bgImage = card.querySelector('.img');

        return {
            name: card.querySelector('.product_name').textContent.trim(),
            price: priceFromText(card.querySelector('.product_price')),
            // 메인 카드는 배경 이미지라 hover 중에 읽히는 _hover 이미지를 원래 이미지로 돌림
            img: img
                ? img.src
                : getComputedStyle(bgImage)
                    .backgroundImage.slice(5, -2)
                    .replace('_hover', ''),
            link: card.querySelector('a').href
        };
    }

    document.querySelectorAll('.product_box').forEach(function (card) {
        const name = card.querySelector('.product_name');

        if (!name) return;

        const addButton = document.createElement('button');
        addButton.type = 'button';
        addButton.className = 'btn_add_cart';
        addButton.setAttribute(
            'aria-label',
            name.textContent.trim() + ' 장바구니 담기'
        );
        addButton.innerHTML = '<i class="fa-solid fa-cart-plus"></i>';
        addButton.addEventListener('click', function () {
            addToCart(getCardItem(card));
        });
        card.appendChild(addButton);

        card.querySelector('a').addEventListener('click', function () {
            addToRecent(getCardItem(card));
        });
    });

    // 상세페이지: 장바구니 담기 / 바로 결제
    const detailBox = document.querySelector('.detail_box');

    if (detailBox) {
        const detailItem = {
            name: detailBox.querySelector('.detail_name').textContent.trim(),
            price: priceFromText(detailBox.querySelector('.detail_price')),
            img: detailBox.querySelector('.detail_img img').src,
            link: location.href.split('#')[0]
        };

        detailBox.querySelector('.btn_cart_add').addEventListener('click', function () {
            addToCart(detailItem);
        });

        detailBox.querySelector('.btn_buy').addEventListener('click', function () {
            if (addToCart(detailItem, true)) {
                location.href = rootUrl + 'sub/checkout/index.html';
            }
        });
    }

    // 주문/결제 페이지 (실제 결제 없이 주문완료까지)
    const checkoutForm = document.querySelector('.checkout_form');

    if (checkoutForm) {
        const orderList = checkoutForm.querySelector('.order_list');
        const orderEmpty = checkoutForm.querySelector('.order_empty');
        const couponSelect = checkoutForm.querySelector('#coupon');
        const pointsInput = checkoutForm.querySelector('#points');
        const ownedPoints = Number(
            checkoutForm.querySelector('[data-owned]').dataset.owned
        );
        const paymentSection = checkoutForm.querySelector('.payment_section');
        const paymentRadios = checkoutForm.querySelectorAll('[name="payment"]');
        const payButton = checkoutForm.querySelector('.btn_pay');
        let summary = {};

        function couponDiscount(option, subtotal) {
            if (option.dataset.rate) {
                // 10원 단위 버림
                return Math.floor((subtotal * option.dataset.rate) / 1000) * 10;
            }

            return Number(option.dataset.amount || 0);
        }

        function updateCheckout() {
            const cart = loadItems(CART_KEY);
            const subtotal = cart.reduce(function (sum, item) {
                return sum + item.price;
            }, 0);

            // 주문 상품 목록
            orderList.innerHTML = '';
            cart.forEach(function (item) {
                const li = document.createElement('li');
                li.innerHTML =
                    '<img alt=""><p class="order_name"></p>' +
                    '<p class="order_price"></p>' +
                    '<button type="button" class="btn_remove"><i class="fa-solid fa-xmark"></i></button>';
                li.querySelector('img').src = item.img;
                li.querySelector('.order_name').textContent = item.name;
                li.querySelector('.order_price').textContent = formatPrice(item.price);

                const removeButton = li.querySelector('.btn_remove');
                removeButton.setAttribute('aria-label', item.name + ' 삭제');
                removeButton.addEventListener('click', function () {
                    saveItems(CART_KEY, loadItems(CART_KEY).filter(function (cartItem) {
                        return cartItem.name !== item.name;
                    }));
                    renderPopups();
                    updateCheckout();
                });

                orderList.appendChild(li);
            });

            checkoutForm.querySelector('.order_count').textContent = cart.length;
            orderEmpty.hidden = cart.length > 0;

            // 쿠폰: 최소 금액이 안 되면 선택 불가
            Array.from(couponSelect.options).forEach(function (option) {
                option.disabled = subtotal < Number(option.dataset.min || 0) ||
                    (option.value !== '' && subtotal === 0);
            });

            if (couponSelect.selectedOptions[0].disabled) couponSelect.value = '';

            const coupon = couponDiscount(couponSelect.selectedOptions[0], subtotal);

            // 적립금: 보유액과 남은 결제금액을 넘지 않게
            const maxPoints = Math.min(ownedPoints, subtotal - coupon);
            const points = Math.min(
                Math.max(parseInt(pointsInput.value, 10) || 0, 0),
                maxPoints
            );
            pointsInput.max = maxPoints;
            // 입력 중에는 그대로 두고, 그 외에는 실제로 적용된 값으로 맞춤
            if (document.activeElement !== pointsInput) pointsInput.value = points;

            const total = subtotal - coupon - points;

            checkoutForm.querySelector('.sum_subtotal').textContent = subtotal.toLocaleString() + '원';
            checkoutForm.querySelector('.sum_coupon').textContent = '-' + coupon.toLocaleString() + '원';
            checkoutForm.querySelector('.sum_points').textContent = '-' + points.toLocaleString() + '원';
            checkoutForm.querySelector('.sum_total').textContent = total.toLocaleString() + '원';

            // 0원이면 결제 수단 없이 바로 받기
            paymentSection.hidden = total === 0;
            paymentRadios.forEach(function (radio) {
                radio.required = total > 0;
            });

            payButton.disabled = !cart.length;
            payButton.textContent = total
                ? total.toLocaleString() + '원 결제하기'
                : '무료로 받기';

            summary = {
                items: cart,
                subtotal: subtotal,
                coupon: coupon,
                points: points,
                total: total
            };
        }

        couponSelect.addEventListener('change', updateCheckout);
        pointsInput.addEventListener('input', updateCheckout);
        pointsInput.addEventListener('blur', updateCheckout);
        checkoutForm.querySelector('.btn_points_all').addEventListener('click', function () {
            pointsInput.value = ownedPoints;
            updateCheckout();
        });

        checkoutForm.addEventListener('submit', function (event) {
            event.preventDefault();
            updateCheckout();

            if (!summary.items.length) return;

            const payment = checkoutForm.querySelector('[name="payment"]:checked');
            const today = new Date();

            summary.number =
                today.getFullYear() +
                String(today.getMonth() + 1).padStart(2, '0') +
                String(today.getDate()).padStart(2, '0') +
                '-' + String(Math.floor(Math.random() * 10000)).padStart(4, '0');
            summary.email = checkoutForm.querySelector('#order_email').value.trim();
            summary.payment = summary.total && payment ? payment.value : '무료';

            saveItems(ORDER_KEY, summary);
            saveItems(CART_KEY, []);
            location.href = 'complete.html';
        });

        updateCheckout();
    }

    // 주문완료 페이지
    const completeBox = document.querySelector('.complete_box');

    if (completeBox) {
        let order = null;

        try {
            order = JSON.parse(localStorage.getItem(ORDER_KEY));
        } catch (error) {
            order = null;
        }

        if (!order || !order.items) {
            completeBox.hidden = true;
            document.querySelector('.complete_empty').hidden = false;
        } else {
            completeBox.querySelector('.complete_email').textContent = order.email;
            completeBox.querySelector('.complete_number').textContent = order.number;
            completeBox.querySelector('.complete_payment').textContent = order.payment;
            completeBox.querySelector('.complete_total').textContent =
                order.total.toLocaleString() + '원';

            const list = completeBox.querySelector('.order_list');

            order.items.forEach(function (item) {
                const li = document.createElement('li');
                li.innerHTML =
                    '<img alt=""><p class="order_name"></p>' +
                    '<button type="button" class="btn_download">다운로드</button>';
                li.querySelector('img').src = item.img;
                li.querySelector('.order_name').textContent = item.name;
                li.querySelector('.btn_download').addEventListener('click', function () {
                    alert('포트폴리오용 화면이라 실제 파일은 내려받을 수 없어요.');
                });
                list.appendChild(li);
            });
        }
    }

    // 3. TOP 버튼 부드럽게 스크롤
    const topButton = document.querySelector('.btn_top');

    if (topButton) {
        // 맨 위에서는 숨기고, 한 화면 정도 내려가면 보여줌 (작은 화면에서 본문을 덜 가리게)
        function toggleTopButton() {
            topButton.classList.toggle('show', window.scrollY > 400);
        }
        toggleTopButton();
        window.addEventListener('scroll', toggleTopButton, { passive: true });

        topButton.addEventListener('click', function (event) {
            event.preventDefault();

            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }

    // 사용법 닫기
    const howUseClose = document.querySelector('.how_use_close');
    const howUseWrap = document.querySelector('.how_use_wrap');

    if (howUseClose) {
        howUseClose.addEventListener('click', function () {
            fadeOut(howUseWrap, 300);
        });
    }

    // 검색창 열고 닫기
    const searchToggle = document.querySelector('.search_toggle');
    const searchBox = document.querySelector('.search_box');
    const searchText = document.querySelector('.search_txt');

    if (searchToggle && searchBox) {
        searchToggle.addEventListener('click', function () {
            searchBox.classList.toggle('on');

            if (searchBox.classList.contains('on')) {
                searchToggle.innerHTML =
                    '<i class="fa-solid fa-xmark"></i>';

                searchToggle.setAttribute(
                    'aria-label',
                    '검색창 닫기'
                );

                if (searchText) {
                    searchText.focus();
                }
            } else {
                searchToggle.innerHTML =
                    '<i class="fa-solid fa-magnifying-glass"></i>';

                searchToggle.setAttribute(
                    'aria-label',
                    '검색창 열기'
                );
            }
        });
    }

    // FAQ 하나만 열기
    const faqDetails = document.querySelectorAll(
        '.faq_box details'
    );

    faqDetails.forEach(function (detail) {
        detail.addEventListener('toggle', function () {
            if (!detail.open) return;

            faqDetails.forEach(function (otherDetail) {
                if (otherDetail !== detail) {
                    otherDetail.removeAttribute('open');
                }
            });
        });
    });

    // 상세페이지가 없는 상품 알림
    const productAlertLinks = document.querySelectorAll(
        '.product_alert a'
    );

    productAlertLinks.forEach(function (link) {
        link.addEventListener('click', function (event) {
            event.preventDefault();

            alert(
                '현재는 만년 업무 플래너만 상세페이지가 제작되어 있습니다.'
            );
        });
    });

    // 실시간 채팅: 자동 응답 데모 (서버 없이 키워드로 정해 둔 답을 보여줌)
    const chatBox = document.querySelector('.chat .chat_box');

    if (chatBox) {
        const chatLog = chatBox.querySelector('.chat_log');
        const chatForm = chatBox.querySelector('.chat_txt_box');
        const chatInput = chatBox.querySelector('.chat_txt');
        const quickButtons = chatBox.querySelectorAll('.chat_quick button');

        // 페이지 깊이가 달라도 링크가 맞도록 사이트 루트(main.js 위치)를 기준으로 경로를 만듦
        // (FAQ 페이지는 메뉴의 '궁금해요'가 href="#"라서 메뉴 링크를 기준으로 삼으면 깨짐)
        const subPath = rootUrl + 'sub/';
        const faqHref = subPath + '4_faq/index.html';

        // 앞에서부터 확인해 처음 맞는 키워드의 답을 사용
        const answers = [
            {
                keywords: ['다운', '파일', '안 열', '안열'],
                text: '아이패드에서 다운로드 버튼을 눌러도 창이 뜨지 않았다면 [파일] 앱 → [다운로드] 폴더를 확인해 주세요. 원본 파일은 미리 백업해 두시는 걸 권장드려요.'
            },
            {
                keywords: ['환불', '취소', '교환'],
                text: '디지털 상품 특성상 다운로드 후에는 교환·환불이 어려워요. 다운로드 내역이 없거나 입금 후 주문을 취소하셨다면 은행명·계좌번호·예금주명을 남겨 주세요.'
            },
            {
                keywords: ['필기', '앱', '굿노트', '노트쉘프', '갤럭시', '삼성'],
                text: 'PDF를 열 수 있는 필기 앱이면 모두 사용할 수 있어요. 아이패드는 굿노트·노트쉘프·플렉슬, 갤럭시 탭은 삼성노트·노트쉘프를 추천드려요.',
                link: { href: subPath + 'howtouse/index.html', label: '사용법 자세히 보기' }
            },
            {
                keywords: ['하이퍼', '링크'],
                text: '굿노트에서는 펜 모드가 켜져 있으면 하이퍼링크가 작동하지 않을 수 있어요. 오른쪽 위 펜 아이콘을 눌러 펜 모드를 꺼 주세요.'
            },
            {
                keywords: ['쿠폰', '할인', '적립'],
                text: '신규회원 10% 할인 쿠폰과 15,000원 이상 구매 시 3,000원 할인 쿠폰이 있어요. 주문/결제 화면에서 쿠폰과 적립금을 함께 사용할 수 있어요.'
            },
            {
                keywords: ['운영', '시간', '상담', '전화', '연락'],
                text: '상담 시간은 평일 09:00~18:00 (점심 12:00~13:00)이에요. 주말·공휴일은 쉬어요.'
            },
            {
                keywords: ['배송', '발송', '메일'],
                text: '디지털 상품이라 배송 없이, 결제 후 입력하신 이메일로 바로 다운로드 링크를 보내 드려요.'
            },
            {
                keywords: ['안녕', '하이', '반가'],
                text: '안녕하세요! 소소한 하루, 소하입니다 :) 무엇이 궁금하세요?'
            }
        ];

        const fallback = {
            text: '죄송해요, 아직 답을 준비하지 못한 질문이에요. 자주 묻는 질문에서 찾아보시거나 아래 버튼을 눌러 주세요.',
            link: { href: faqHref, label: '자주 묻는 질문 보기' }
        };

        function findAnswer(message) {
            const text = message.replace(/\s/g, '');

            for (let i = 0; i < answers.length; i++) {
                const matched = answers[i].keywords.some(function (keyword) {
                    return text.indexOf(keyword.replace(/\s/g, '')) !== -1;
                });

                if (matched) return answers[i];
            }

            return fallback;
        }

        // 사용자가 입력한 글은 textContent로만 넣어 HTML이 실행되지 않게 함
        function addMessage(text, who, link) {
            const bubble = document.createElement('p');
            bubble.className = 'msg ' + who;
            bubble.textContent = text;

            if (link) {
                const anchor = document.createElement('a');
                anchor.href = link.href;
                anchor.textContent = link.label;
                bubble.appendChild(document.createElement('br'));
                bubble.appendChild(anchor);
            }

            chatLog.appendChild(bubble);
            chatLog.scrollTop = chatLog.scrollHeight;
            return bubble;
        }

        function send(message) {
            message = message.trim();
            if (!message) return;

            addMessage(message, 'user');

            const typing = addMessage('입력 중…', 'bot typing');
            const answer = findAnswer(message);

            setTimeout(function () {
                typing.remove();
                addMessage(answer.text, 'bot', answer.link);
            }, 600);
        }

        chatForm.addEventListener('submit', function (event) {
            event.preventDefault();
            send(chatInput.value);
            chatInput.value = '';
            chatInput.focus();
        });

        quickButtons.forEach(function (button) {
            button.addEventListener('click', function () {
                send(button.textContent);
            });
        });
    }
});
